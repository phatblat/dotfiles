mod guard_eval;
mod hook;
mod manifest;
mod paths;
mod policy;

use std::collections::HashMap;
use std::path::{Path, PathBuf};

/// Hand-rolled `--flag value` parser (no CLI dependency is in scope for this
/// crate; see the de-risk plan's fixed dependency list). Mirrors
/// `parse_guard_args`' flag_map (`scripts/agent-harnesses.py:2170-2206`) in
/// spirit: every flag takes exactly one value, unknown flags are rejected.
fn parse_flags(args: &[String]) -> Result<HashMap<String, String>, String> {
    let mut out = HashMap::new();
    let mut i = 0;
    while i < args.len() {
        let key = &args[i];
        let Some(name) = key.strip_prefix("--") else {
            return Err(format!("unexpected argument: {key}"));
        };
        let Some(value) = args.get(i + 1) else {
            return Err(format!("flag {key} requires a value"));
        };
        out.insert(name.to_string(), value.clone());
        i += 2;
    }
    Ok(out)
}

fn manifest_path(root: &Path) -> PathBuf {
    root.join(".agents").join("harness").join("generated-paths.json")
}

/// Default `--cwd` when the flag is omitted, matching `parse_guard_args`'
/// `"cwd": str(ROOT)` default (`scripts/agent-harnesses.py:2196`). See
/// `paths::find_root` for how ROOT is derived for a compiled, installed
/// binary versus Python's script-location comparison.
fn default_cwd() -> String {
    paths::find_root().to_string_lossy().into_owned()
}

/// `ness guard --harness <slug> --tool <name> [--command|--path|--content|--cwd]`
/// — drop-in for `python3 scripts/agent-harnesses.py guard …`
/// (`command_guard`, agent-harnesses.py:695-725).
fn run_guard(flags: &HashMap<String, String>) -> i32 {
    let Some(harness) = flags.get("harness") else {
        eprintln!("ness guard: --harness is required");
        return 2;
    };
    let Some(tool) = flags.get("tool") else {
        eprintln!("ness guard: --tool is required");
        return 2;
    };
    let command = flags.get("command").cloned().unwrap_or_default();
    let path = flags.get("path").cloned().unwrap_or_default();
    let content = flags.get("content").cloned().unwrap_or_default();
    let cwd = flags.get("cwd").cloned().unwrap_or_else(default_cwd);

    let root = paths::find_root();
    let manifest = manifest_path(&root);
    let decision =
        guard_eval::evaluate_with_manifest(tool, &command, &path, &content, &cwd, &manifest);

    let payload = serde_json::json!({
        "harness": harness,
        "tool": tool,
        "decision": decision.decision,
        "reason": decision.reason,
    });
    println!("{payload}");
    if decision.allowed() {
        0
    } else {
        2
    }
}

/// `ness hook --harness <slug> --tool <write|bash>` — see `hook.rs`.
fn run_hook(flags: &HashMap<String, String>) -> i32 {
    let Some(harness) = flags.get("harness") else {
        eprintln!("ness hook: --harness is required");
        return 2;
    };
    let Some(tool) = flags.get("tool") else {
        eprintln!("ness hook: --tool is required (write or bash)");
        return 2;
    };
    let cwd = flags.get("cwd").cloned().unwrap_or_else(default_cwd);
    let root = paths::find_root();
    let manifest = manifest_path(&root);

    match tool.as_str() {
        "bash" => hook::run_bash(harness, &cwd, &manifest),
        "write" => hook::run_write(harness, &cwd, &manifest),
        other => {
            eprintln!("ness hook: unsupported --tool '{other}' (expected write or bash)");
            return 2;
        }
    }
    // Hook responses always exit 0: Claude/Codex read the decision from the
    // presence (or absence) of `hookSpecificOutput` in stdout JSON, not from
    // the process exit code — unlike `guard`, which exits 2 on deny.
    0
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let Some(subcommand) = args.first().cloned() else {
        eprintln!("usage: ness <guard|hook> --harness <slug> ...");
        std::process::exit(2);
    };

    let flags = match parse_flags(&args[1..]) {
        Ok(flags) => flags,
        Err(err) => {
            eprintln!("ness: {err}");
            std::process::exit(2);
        }
    };

    let code = match subcommand.as_str() {
        "guard" => run_guard(&flags),
        "hook" => run_hook(&flags),
        other => {
            eprintln!("ness: unknown subcommand '{other}' (expected guard or hook)");
            2
        }
    };
    std::process::exit(code);
}
