mod active;
mod guard_eval;
mod hook;
mod manifest;
mod paths;
mod policy;
mod policy_cmd;
mod shell;
mod policy_file;
use policy_file::Compiled;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
const USAGE: &str = "\
usage: ness <guard|hook|policy> ... | ness [--version | --help]
subcommands:
  guard    run the guard (see `ness guard --help`)
  hook     run the hook adapter (see `ness hook --help`)
  policy   policy actions: check, apply, active

flags:
  -V, --version   print version and exit
  -h, --help      print this text and exit
";

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
    root.join(".agents")
        .join("harness")
        .join("generated-paths.json")
}

/// Default `--cwd` when the flag is omitted, matching `parse_guard_args`'
/// `"cwd": str(ROOT)` default (`scripts/agent-harnesses.py:2196`). See
/// `paths::find_root` for how ROOT is derived for a compiled, installed
/// binary versus Python's script-location comparison.
fn default_cwd() -> String {
    paths::find_root().to_string_lossy().into_owned()
}

/// `ness guard --harness <slug> --tool <name> [--command|--path|--content|--cwd]
/// [--approved <newline-separated prompt reasons>]`
/// — drop-in for `python3 scripts/agent-harnesses.py guard …`
/// (`command_guard`, agent-harnesses.py:695-725). `--approved` carries
/// command-level reasons the omp hook's user approved for the session.
fn run_guard(p: Result<&Compiled, &str>, flags: &HashMap<String, String>) -> i32 {
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
        guard_eval::evaluate_with_manifest(p, tool, &command, &path, &content, &cwd, &manifest);

    let payload = guard_eval::verdict_json(harness, tool, &decision);
    println!("{payload}");
    if decision.allowed() {
        0
    } else {
        2
    }
}

/// `ness hook --harness <slug> [--tool <write|bash>]` — see `hook.rs`.
/// `--tool` is required for `claude`/`codex` (which subcommand of the
/// two-shim chain they replace is not derivable from the payload alone) and
/// rejected for `grok`/`crush`/`antigravity`/`cursor` (each of those sends
/// a single normalized payload that classifies itself).
fn run_hook(p: Result<&Compiled, &str>, flags: &HashMap<String, String>) -> i32 {
    let Some(harness) = flags.get("harness") else {
        eprintln!("ness hook: --harness is required");
        return 2;
    };
    let cwd = flags.get("cwd").cloned().unwrap_or_else(default_cwd);
    let root = paths::find_root();
    let manifest = manifest_path(&root);

    match harness.as_str() {
        "claude" | "codex" => {
            let Some(tool) = flags.get("tool") else {
                eprintln!("ness hook: --tool is required (write or bash)");
                return 2;
            };
            match tool.as_str() {
                "bash" => hook::run_bash(p, harness, &cwd, &manifest),
                "write" => hook::run_write(p, harness, &cwd, &manifest),
                other => {
                    eprintln!("ness hook: unsupported --tool '{other}' (expected write or bash)");
                    return 2;
                }
            }
            // Hook responses always exit 0: Claude/Codex read the decision
            // from the presence (or absence) of `hookSpecificOutput` in
            // stdout JSON, not from the process exit code — unlike `guard`,
            // which exits 2 on deny.
            0
        }
        "grok" | "crush" | "antigravity" | "cursor" => {
            if flags.contains_key("tool") {
                eprintln!("ness hook: --tool is only valid for claude and codex");
                return 2;
            }
            match harness.as_str() {
                "grok" => hook::run_grok(p, &cwd, &manifest),
                "crush" => hook::run_crush(p, &cwd, &manifest),
                "antigravity" => hook::run_antigravity(p, &cwd, &manifest),
                _ => hook::run_cursor(p, &cwd, &manifest),
            }
        }
        other => {
            eprintln!(
                "ness hook: unsupported --harness '{other}' (expected claude, codex, grok, crush, antigravity, or cursor)"
            );
            2
        }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();

    if args.first().is_some_and(|a| a == "--version" || a == "-V") {
        println!("ness {}", env!("CARGO_PKG_VERSION"));
        std::process::exit(0);
    }
    if args.first().is_some_and(|a| a == "--help" || a == "-h") {
        print!("{USAGE}");
        std::process::exit(0);
    }

    let Some(subcommand) = args.first().cloned() else {
        eprint!("{USAGE}");
        std::process::exit(2);
    };

    match subcommand.as_str() {
        "help" => {
            print!("{USAGE}");
            std::process::exit(0);
        }
        "version" => {
            println!("ness {}", env!("CARGO_PKG_VERSION"));
            std::process::exit(0);
        }
        "policy" => {
            std::process::exit(policy_cmd::run(&args[1..]));
        }
        _ => {}
    }

    let flags = match parse_flags(&args[1..]) {
        Ok(flags) => flags,
        Err(err) => {
            eprintln!("ness: {err}");
            std::process::exit(2);
        }
    };

    // Fail closed: a load failure is a reason string that becomes a deny on
    // every verdict, emitted in each harness's native output shape. Never
    // panic here: an uncaught panic exits non-zero, which Claude treats as a
    // non-blocking hook error. That is why shell::classify catches its own panics.
    let mut policy = active::load();
    // `ness guard --approved`: command-level prompt reasons the user approved for
    // the session. Only `shell::approvable` sites honor them.
    if subcommand == "guard" {
        if let (Ok(c), Some(a)) = (policy.as_mut(), flags.get("approved")) {
            c.shell.approved = a.split('\n').filter(|s| !s.is_empty()).map(str::to_owned).collect();
        }
    }
    let p = policy.as_ref().map_err(String::as_str);

    let code = match subcommand.as_str() {
        "guard" => run_guard(p, &flags),
        "hook" => run_hook(p, &flags),
        other => {
            eprintln!("ness: unknown subcommand '{other}' (expected guard, hook, or policy)");
            2
        }
    };
    std::process::exit(code);
}
