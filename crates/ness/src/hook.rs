//! `ness hook --harness <slug> --tool <write|bash>`: reads a harness's
//! native `PreToolUse` payload on stdin and writes its native response on
//! stdout, replacing the bash + python3 + jq shim chain with one process.
//!
//! `--tool` mirrors the fact that today's shims hardcode which guard mode
//! they run: `write-guard.sh` always calls the guard with `--tool write`,
//! `bash-guard.sh` always calls it with `--tool bash`, regardless of the
//! payload's own `tool_name` field (`.claude/hooks/scripts/write-guard.sh:20`,
//! `bash-guard.sh:42`). This subcommand keeps that same split explicit
//! rather than re-deriving it by sniffing `tool_name`, which differs across
//! harnesses (Claude's Bash tool is not necessarily named the same as
//! Codex's).

use crate::guard_eval::evaluate_with_manifest;
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

fn read_stdin() -> Value {
    let mut buf = String::new();
    let _ = std::io::stdin().read_to_string(&mut buf);
    serde_json::from_str(&buf).unwrap_or(Value::Null)
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

/// Port of `.claude/hooks/scripts/bash-guard.sh` / `.codex/hooks/scripts/bash-guard.sh`
/// (the two are structurally identical: same extraction, same response shape).
pub fn run_bash(harness: &str, cwd: &str, manifest_path: &Path) {
    let payload = read_stdin();
    let command = str_or_empty(&payload, "/tool_input/command");
    if command.trim().is_empty() {
        return; // exit 0, no output — matches `[ -z "$command" ] && exit 0`.
    }

    let decision = evaluate_with_manifest(
        "bash",
        &command,
        "",
        "",
        cwd,
        manifest_path,
    );
    let _ = harness; // response shape does not currently vary by harness.
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
    let payload = read_stdin();
    let tool_name = get_str(&payload, "/tool_name").unwrap_or("");
    let command = str_or_empty(&payload, "/tool_input/command");

    let is_apply_patch =
        harness == "codex" && (tool_name == "apply_patch" || command.starts_with("*** Begin Patch"));

    if is_apply_patch {
        for path in apply_patch_all_paths(&command) {
            if path.is_empty() {
                continue;
            }
            let decision = evaluate_with_manifest("write", "", &path, "", cwd, manifest_path);
            if decision.decision == "deny" {
                print_deny(&decision.reason);
                return;
            }
        }
        let added_content = apply_patch_added_content(&command);
        let decision = evaluate_with_manifest("write", "", "", &added_content, cwd, manifest_path);
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
