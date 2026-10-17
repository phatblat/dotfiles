//! `ness hook --harness <slug> [--tool <write|bash>]`: reads a harness's
//! native `PreToolUse` payload on stdin and writes its native response on
//! stdout, replacing the bash + python3 + jq shim chain with one process.
//!
//! `--tool` mirrors the fact that today's Claude/Codex shims hardcode which
//! guard mode they run: `write-guard.sh` always calls the guard with
//! `--tool write`, `bash-guard.sh` always calls it with `--tool bash`,
//! regardless of the payload's own `tool_name` field
//! (`.claude/hooks/scripts/write-guard.sh:20`, `bash-guard.sh:42`). This
//! subcommand keeps that same split explicit rather than re-deriving it by
//! sniffing `tool_name`, which differs across harnesses (Claude's Bash tool
//! is not necessarily named the same as Codex's).
//!
//! `grok`, `crush`, `antigravity`, and `cursor` take no `--tool`: each sends
//! one tool call in its own native shape, and each gets its native reply:
//! - grok: `toolName`/`toolInput` (camelCase); `{"decision":...}` + exit 2 on deny.
//! - crush: `tool_name`/`tool_input`; stderr + exit 2 on deny.
//! - cursor: `tool_name`/`tool_input`; `{"permission":"deny",...}`.
//! - antigravity: `toolCall.args` (`CommandLine`/`TargetFile`/`CodeContent`/
//!   `ReplacementChunks`); `{"decision":"deny",...}`.
//!
//! `classify` sorts a `tool_input` object into bash-vs-write the same way the
//! Python wrappers did (`render_grok_guard`, `render_crush_guard`,
//! `scripts/agent-harnesses.py`).

use crate::guard_eval::evaluate_with_manifest;
use crate::policy::GuardDecision;
use serde_json::Value;
use std::io::Read;
use std::path::Path;

fn get_str<'a>(value: &'a Value, pointer: &str) -> Option<&'a str> {
    value.pointer(pointer).and_then(|v| v.as_str())
}

/// jq `.a // .b // empty`: only `null` and `false` are falsy in jq, so an
/// empty string from the first field is still used as-is.
fn jq_alt(value: &Value, pointers: &[&str]) -> String {
    for pointer in pointers {
        if let Some(v) = value.pointer(pointer) {
            if !v.is_null() && *v != Value::Bool(false) {
                if let Some(s) = v.as_str() {
                    return s.to_string();
                }
            }
        }
    }
    String::new()
}

fn str_or_empty(value: &Value, pointer: &str) -> String {
    value
        .pointer(pointer)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string()
}

fn print_deny(reason: &str) {
    let payload = serde_json::json!({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    });
    println!("{payload}");
}

fn print_warn(reason: &str) {
    println!("{}", serde_json::json!({"systemMessage": reason}));
}

/// Port of `apply_patch_all_paths` (`.codex/hooks/scripts/apply-patch-input.sh:11-22`):
/// every `*** Add/Update/Delete File:` and `*** Move to:` target, first
/// occurrence only, in appearance order.
fn apply_patch_all_paths(patch_text: &str) -> Vec<String> {
    let mut seen = std::collections::HashSet::new();
    let mut out = Vec::new();
    for line in patch_text.lines() {
        let target = line
            .strip_prefix("*** Add File: ")
            .or_else(|| line.strip_prefix("*** Update File: "))
            .or_else(|| line.strip_prefix("*** Delete File: "))
            .or_else(|| line.strip_prefix("*** Move to: "));
        if let Some(target) = target {
            if seen.insert(target.to_string()) {
                out.push(target.to_string());
            }
        }
    }
    out
}

/// Port of `apply_patch_added_content` (`apply-patch-input.sh:37-43`): every
/// added line (`+`, not `+++`), stripped of its leading `+`, newline-joined.
fn apply_patch_added_content(patch_text: &str) -> String {
    patch_text
        .lines()
        .filter(|line| line.starts_with('+') && !line.starts_with("+++"))
        .map(|line| &line[1..])
        .collect::<Vec<_>>()
        .join("\n")
}

/// Write-checks every apply_patch target, then the added content. Shared by
/// Codex's write hook and grok's `apply_patch` tool. Returns the first deny.
fn evaluate_apply_patch(patch_text: &str, cwd: &str, manifest: &Path) -> GuardDecision {
    for path in apply_patch_all_paths(patch_text) {
        if path.is_empty() {
            continue;
        }
        let decision = evaluate_with_manifest("write", "", &path, "", cwd, manifest);
        if decision.decision == "deny" {
            return decision;
        }
    }
    evaluate_with_manifest(
        "write",
        "",
        "",
        &apply_patch_added_content(patch_text),
        cwd,
        manifest,
    )
}

/// Port of `.claude/hooks/scripts/bash-guard.sh` / `.codex/hooks/scripts/bash-guard.sh`
/// (the two are structurally identical: same extraction, same response shape).
pub fn run_bash(harness: &str, cwd: &str, manifest_path: &Path) {
    let payload = match read_stdin_object() {
        Ok(v) => v,
        Err(e) => {
            print_deny(&format!("shared guard failed closed: {e}"));
            return;
        }
    };
    let command = str_or_empty(&payload, "/tool_input/command");
    if command.trim().is_empty() {
        return; // exit 0, no output — matches `[ -z "$command" ] && exit 0`.
    }

    let decision = evaluate_with_manifest("bash", &command, "", "", cwd, manifest_path);
    if harness == "codex" && crate::policy::is_interactive_launch(&command) {
        print_deny(
            "Interactive shell/REPL launch blocked: input sent with write_stdin never re-runs the guard. Run each command directly.",
        );
        return;
    }
    match decision.decision.as_str() {
        "deny" => print_deny(&decision.reason),
        "warn" => print_warn(&decision.reason),
        _ => {}
    }
}

/// Port of `.claude/hooks/scripts/write-guard.sh` / `.codex/hooks/scripts/write-guard.sh`.
/// Codex's apply_patch branch is gated on `harness == "codex"`, matching the
/// plan's explicit callout that only Codex sends apply_patch payloads;
/// Claude never emits `tool_name == "apply_patch"` or a `*** Begin Patch`
/// command, so gating is a safety margin rather than a behavior difference.
pub fn run_write(harness: &str, cwd: &str, manifest_path: &Path) {
    let payload = match read_stdin_object() {
        Ok(v) => v,
        Err(e) => {
            print_deny(&format!("shared guard failed closed: {e}"));
            return;
        }
    };
    let tool_name = get_str(&payload, "/tool_name").unwrap_or("");
    let command = str_or_empty(&payload, "/tool_input/command");

    let is_apply_patch = harness == "codex"
        && (tool_name == "apply_patch" || command.starts_with("*** Begin Patch"));

    if is_apply_patch {
        let decision = evaluate_apply_patch(&command, cwd, manifest_path);
        if decision.decision == "deny" {
            print_deny(&decision.reason);
        }
        return;
    }

    let file_path = jq_alt(&payload, &["/tool_input/file_path", "/tool_input/path"]);
    let content = format!(
        "{}{}",
        str_or_empty(&payload, "/tool_input/content"),
        str_or_empty(&payload, "/tool_input/new_string")
    );
    let decision = evaluate_with_manifest("write", "", &file_path, &content, cwd, manifest_path);
    if decision.decision == "deny" {
        print_deny(&decision.reason);
    }
}

/// Reads and parses stdin as a JSON object, failing closed (as `Err`) on
/// unreadable or non-object input. Used by `run_bash` and `run_write` to match
/// the grok/crush/antigravity/cursor Python wrappers' own fail-closed
/// behavior on a bad payload.
fn read_stdin_object() -> Result<Value, &'static str> {
    let mut buf = String::new();
    std::io::stdin()
        .read_to_string(&mut buf)
        .map_err(|_| "unreadable hook payload")?;
    let value: Value = serde_json::from_str(&buf).map_err(|_| "unreadable hook payload")?;
    if value.is_object() {
        Ok(value)
    } else {
        Err("payload is not a dict")
    }
}

const PATH_KEYS: [&str; 3] = ["file_path", "path", "target_file"];
const CONTENT_KEYS: [&str; 5] = ["content", "contents", "new_string", "new_text", "new_str"];

/// First key in `keys` holding a non-empty string, else `""`.
fn first_nonempty_str(obj: &Value, keys: &[&str]) -> String {
    for key in keys {
        if let Some(s) = obj.get(*key).and_then(|v| v.as_str()) {
            if !s.is_empty() {
                return s.to_string();
            }
        }
    }
    String::new()
}

/// Concatenation of every string-valued key in `keys`, in key order.
fn concat_strs(obj: &Value, keys: &[&str]) -> String {
    let mut out = String::new();
    for key in keys {
        if let Some(s) = obj.get(*key).and_then(|v| v.as_str()) {
            out.push_str(s);
        }
    }
    out
}

struct Classified {
    tool: &'static str,
    command: String,
    path: String,
    content: String,
}

/// Sorts a normalized `tool_input`/`toolInput` object into bash-vs-write,
/// the way `render_grok_guard`/`render_crush_guard` classified a call by
/// whether it carried a `command` or a path. `flatten_edits` additionally
/// folds a `multiedit`-style `edits[]` array's `new_string`/`new_text`
/// fields into `content`, matching `render_crush_guard`'s flattening (crush
/// is the only normalized wrapper that ever receives `edits`).
fn classify(tool_input: &Value, flatten_edits: bool) -> Option<Classified> {
    let empty = Value::Object(serde_json::Map::new());
    let obj = if tool_input.is_object() {
        tool_input
    } else {
        &empty
    };
    let command = obj
        .get("command")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let path = first_nonempty_str(obj, &PATH_KEYS);
    let mut content = concat_strs(obj, &CONTENT_KEYS);
    if flatten_edits {
        if let Some(edits) = obj.get("edits").and_then(|v| v.as_array()) {
            for edit in edits {
                if edit.is_object() {
                    content.push_str(&concat_strs(edit, &CONTENT_KEYS));
                }
            }
        }
    }
    if !command.is_empty() {
        Some(Classified {
            tool: "bash",
            command,
            path,
            content,
        })
    } else if !path.is_empty() {
        Some(Classified {
            tool: "write",
            command,
            path,
            content,
        })
    } else {
        None
    }
}

/// `payload.cwd` when it is a non-empty string, else `default_cwd`.
fn payload_cwd(payload: &Value, default_cwd: &str) -> String {
    payload
        .get("cwd")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .unwrap_or_else(|| default_cwd.to_string())
}

/// Port of `render_grok_guard`. grok's payload is camelCase
/// (`toolName`/`toolInput`); on deny it prints `{"decision":"deny",...}` and
/// exits 2, on warn it writes the reason to stderr and still allows (grok
/// has no separate warning channel), and a bad payload fails closed with
/// the same JSON shape rather than silently allowing.
pub fn run_grok(default_cwd: &str, manifest: &Path) -> i32 {
    let payload = match read_stdin_object() {
        Ok(v) => v,
        Err(e) => {
            println!(
                "{}",
                serde_json::json!({"decision": "deny", "reason": format!("shared guard failed closed: {e}")})
            );
            return 2;
        }
    };
    let empty = Value::Object(serde_json::Map::new());
    let tool_input = payload.get("toolInput").unwrap_or(&empty);
    let patch = tool_input
        .get("patch")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if get_str(&payload, "/toolName") == Some("apply_patch") || patch.starts_with("*** Begin Patch")
    {
        let cwd = payload_cwd(&payload, default_cwd);
        let decision = evaluate_apply_patch(patch, &cwd, manifest);
        if decision.decision == "deny" {
            println!(
                "{}",
                serde_json::json!({"decision": "deny", "reason": decision.reason})
            );
            return 2;
        }
        println!("{}", serde_json::json!({"decision": "allow"}));
        return 0;
    }
    let Some(c) = classify(tool_input, false) else {
        println!("{}", serde_json::json!({"decision": "allow"}));
        return 0;
    };
    let cwd = payload_cwd(&payload, default_cwd);
    let decision = evaluate_with_manifest(c.tool, &c.command, &c.path, &c.content, &cwd, manifest);
    match decision.decision.as_str() {
        "deny" => {
            println!(
                "{}",
                serde_json::json!({"decision": "deny", "reason": decision.reason})
            );
            2
        }
        "warn" => {
            eprintln!("{}", decision.reason);
            println!("{}", serde_json::json!({"decision": "allow"}));
            0
        }
        _ => {
            println!("{}", serde_json::json!({"decision": "allow"}));
            0
        }
    }
}

/// Port of `render_crush_guard`. crush's payload is snake_case
/// (`tool_name`/`tool_input`, with `edits[]` flattened for `multiedit`); on
/// deny it writes the reason to stderr and exits 2 (no stdout — crush reads
/// the block from the exit code), on warn it writes to stderr but still
/// allows (exit 0), and on allow it stays silent on purpose: unlike grok,
/// crush treats a printed `{"decision":"allow"}` on stdout as extra output
/// to surface to the user rather than as a no-op, so allow must produce no
/// stdout at all.
pub fn run_crush(default_cwd: &str, manifest: &Path) -> i32 {
    let payload = match read_stdin_object() {
        Ok(v) => v,
        Err(e) => {
            eprintln!("shared guard failed closed: {e}");
            return 2;
        }
    };
    let empty = Value::Object(serde_json::Map::new());
    let tool_input = payload.get("tool_input").unwrap_or(&empty);
    let Some(c) = classify(tool_input, true) else {
        return 0;
    };
    let cwd = payload_cwd(&payload, default_cwd);
    let decision = evaluate_with_manifest(c.tool, &c.command, &c.path, &c.content, &cwd, manifest);
    match decision.decision.as_str() {
        "deny" => {
            eprintln!("{}", decision.reason);
            2
        }
        "warn" => {
            eprintln!("{}", decision.reason);
            0
        }
        _ => 0,
    }
}

/// `antigravity` (agy). The payload is `{toolCall: {name, args}, workspacePaths}`
/// with PascalCase args: `CommandLine`/`Cwd` for shell calls, `TargetFile` plus
/// `CodeContent` (write) or `ReplacementChunks[].ReplacementContent` (edit) for
/// file calls. agy reads only the stdout decision, so every outcome exits 0:
/// deny prints `{"decision":"deny","reason":R}`; allow and warn print `{}`
/// (an empty decision means "use the normal permission flow", whereas an
/// explicit `allow` would bypass agy's own prompts and sandbox).
pub fn run_antigravity(default_cwd: &str, manifest: &Path) -> i32 {
    let deny = |reason: &str| {
        println!(
            "{}",
            serde_json::json!({"decision": "deny", "reason": reason})
        );
    };
    let payload = match read_stdin_object() {
        Ok(v) => v,
        Err(e) => {
            deny(&format!("shared guard failed closed: {e}"));
            return 0;
        }
    };
    let Some(tool_call) = payload.get("toolCall").filter(|v| v.is_object()) else {
        deny("shared guard failed closed: payload has no toolCall");
        return 0;
    };
    let empty = Value::Object(serde_json::Map::new());
    let args = tool_call
        .get("args")
        .filter(|v| v.is_object())
        .unwrap_or(&empty);
    let str_arg = |key: &str| -> String {
        args.get(key)
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string()
    };
    let command = str_arg("CommandLine");
    let path = str_arg("TargetFile");
    let mut parts = vec![str_arg("CodeContent")];
    if let Some(chunks) = args.get("ReplacementChunks").and_then(|v| v.as_array()) {
        for chunk in chunks {
            if let Some(s) = chunk.get("ReplacementContent").and_then(|v| v.as_str()) {
                parts.push(s.to_string());
            }
        }
    }
    let content = parts
        .into_iter()
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join("\n");
    let cwd = [str_arg("Cwd"), str_or_empty(&payload, "/workspacePaths/0")]
        .into_iter()
        .find(|s| !s.is_empty())
        .unwrap_or_else(|| default_cwd.to_string());

    let tool = if !command.is_empty() {
        "bash"
    } else if !path.is_empty() {
        "write"
    } else {
        println!("{{}}");
        return 0;
    };
    let decision = evaluate_with_manifest(tool, &command, &path, &content, &cwd, manifest);
    match decision.decision.as_str() {
        "deny" => deny(&decision.reason),
        "warn" => {
            eprintln!("{}", decision.reason);
            println!("{{}}");
        }
        _ => println!("{{}}"),
    }
    0
}

/// `cursor` (cursor-agent). The payload is `{tool_name, tool_input, cwd, ...}`.
/// Deny prints `{"permission":"deny","user_message":R,"agent_message":R}`;
/// allow and warn print `{}` (`permission: allow` would bypass Cursor's
/// allowlist prompts). Always exits 0.
pub fn run_cursor(default_cwd: &str, manifest: &Path) -> i32 {
    let deny = |reason: &str| {
        println!(
            "{}",
            serde_json::json!({"permission": "deny", "user_message": reason, "agent_message": reason})
        );
    };
    let payload = match read_stdin_object() {
        Ok(v) => v,
        Err(e) => {
            deny(&format!("shared guard failed closed: {e}"));
            return 0;
        }
    };
    let empty = Value::Object(serde_json::Map::new());
    let tool_input = payload.get("tool_input").unwrap_or(&empty);
    let Some(c) = classify(tool_input, true) else {
        println!("{{}}");
        return 0;
    };
    let cwd = payload_cwd(&payload, default_cwd);
    let decision = evaluate_with_manifest(c.tool, &c.command, &c.path, &c.content, &cwd, manifest);
    match decision.decision.as_str() {
        "deny" => deny(&decision.reason),
        "warn" => {
            eprintln!("{}", decision.reason);
            println!("{{}}");
        }
        _ => println!("{{}}"),
    }
    0
}
