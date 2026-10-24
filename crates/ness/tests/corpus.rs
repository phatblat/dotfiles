//! Corpus and shim conformance tests for `ness`, replacing
//! `scripts/ness-parity.py` and the guard-behavior bats tests it exercised.
//!
//! Fixture schema:
//! - `.config/ness/cases/*.json` (repo root): `harness`, `tool`,
//!   `command`/`path`/`content`/`cwd` (nullable) keys plus
//!   `"expected": {"decision": "allow"|"warn"|"prompt"|"deny", "reason": "<string>"}`.
//! - `crates/ness/tests/hook_corpus/*.json`: `shim`, `payload` keys plus
//!   `"expected": {"exit": <int>, "stdout": <JSON value or null when the
//!   shim printed nothing>, "stderr": "<optional, must equal the trimmed
//!   stderr>"}`.
//!
//! Shim table (relative to the repo root):
//!
//! | shim          | path                                                           |
//! |---------------|-----------------------------------------------------------------|
//! | claude-bash   | `.claude/hooks/scripts/bash-guard.sh`                            |
//! | claude-write  | `.claude/hooks/scripts/write-guard.sh`                           |
//! | codex-bash    | `.codex/hooks/scripts/bash-guard.sh`                             |
//! | codex-write   | `.codex/hooks/scripts/write-guard.sh`                            |
//! | grok          | `.grok/scripts/harness-guard.sh`                                 |
//! | crush         | `.config/crush/hooks/harness-guard.sh`                           |
//! | antigravity   | `.agents/harness/adapters/antigravity/scripts/harness-guard.sh`  |
//! | cursor        | `.agents/harness/adapters/cursor/scripts/harness-guard.sh`       |

use serde_json::Value;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicUsize, Ordering};

fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../..")
        .canonicalize()
        .expect("repo root")
}

fn built_ness() -> PathBuf {
    PathBuf::from(env!("CARGO_BIN_EXE_ness"))
}

fn load(dir: &str) -> Vec<(String, Value)> {
    let path = match dir {
        "corpus" => repo_root().join(".config").join("ness").join("cases"),
        other => Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("tests")
            .join(other),
    };
    let mut entries: Vec<(String, Value)> = std::fs::read_dir(&path)
        .unwrap_or_else(|e| panic!("read {}: {e}", path.display()))
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.path().extension().and_then(|s| s.to_str()) == Some("json"))
        .map(|entry| {
            let name = entry.file_name().to_string_lossy().into_owned();
            let text = std::fs::read_to_string(entry.path())
                .unwrap_or_else(|e| panic!("read {name}: {e}"));
            let value: Value =
                serde_json::from_str(&text).unwrap_or_else(|e| panic!("parse {name}: {e}"));
            (name, value)
        })
        .collect();
    entries.sort_by(|a, b| a.0.cmp(&b.0));
    entries
}

/// Port of `ness-parity.py`'s `build_args`.
fn guard_args(case: &Value) -> Vec<String> {
    let mut args = vec![
        "--harness".to_string(),
        case["harness"].as_str().expect("harness").to_string(),
        "--tool".to_string(),
        case["tool"].as_str().expect("tool").to_string(),
    ];
    for (flag, key) in [
        ("--command", "command"),
        ("--path", "path"),
        ("--content", "content"),
        ("--cwd", "cwd"),
    ] {
        if let Some(v) = case.get(key).and_then(Value::as_str) {
            args.push(flag.to_string());
            args.push(v.to_string());
        }
    }
    args
}

fn paths_home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").expect("HOME must be set"))
}

fn run_guard(binary: &Path, home: &Path, case: &Value) -> (i32, Value) {
    let output = Command::new(binary)
        .arg("guard")
        .args(guard_args(case))
        .current_dir(repo_root())
        .env("HOME", home)
        .output()
        .unwrap_or_else(|e| panic!("spawn {}: {e}", binary.display()));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let parsed: Value = serde_json::from_str(stdout.trim()).unwrap_or(Value::Null);
    (output.status.code().unwrap_or(-1), parsed)
}

fn guard_mismatches(binary: &Path, home: &Path) -> Vec<String> {
    let mut mismatches = Vec::new();
    let cases = load("corpus");
    assert!(cases.len() >= 132, "corpus has only {} cases", cases.len());
    for (name, case) in cases {
        let expected_decision = case["expected"]["decision"].as_str().expect("decision");
        let expected_reason = case["expected"]["reason"].as_str().expect("reason");
        let expected_exit = if expected_decision == "deny" { 2 } else { 0 };
        let (exit, got) = run_guard(binary, home, &case);
        let got_decision = got["decision"].as_str().unwrap_or("<missing>");
        let got_reason = got["reason"].as_str().unwrap_or("<missing>");
        if got_decision != expected_decision
            || got_reason != expected_reason
            || exit != expected_exit
        {
            mismatches.push(format!(
                "{name}: expected ({expected_decision:?}, {expected_reason:?}) exit {expected_exit}; got ({got_decision:?}, {got_reason:?}) exit {exit}"
            ));
        }
    }
    mismatches
}

static TEMP_COUNTER: AtomicUsize = AtomicUsize::new(0);

fn temp_dir() -> TempHome {
    let n = TEMP_COUNTER.fetch_add(1, Ordering::SeqCst);
    let dir = std::env::temp_dir().join(format!("ness-test-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap_or_else(|e| panic!("mkdir {}: {e}", dir.display()));
    TempHome(dir)
}

/// A temp directory removed on drop, except when the test is panicking so
/// the failure can be inspected.
struct TempHome(PathBuf);

impl std::ops::Deref for TempHome {
    type Target = Path;
    fn deref(&self) -> &Path {
        &self.0
    }
}

impl AsRef<std::ffi::OsStr> for TempHome {
    fn as_ref(&self) -> &std::ffi::OsStr {
        self.0.as_os_str()
    }
}

impl Drop for TempHome {
    fn drop(&mut self) {
        if std::thread::panicking() {
            eprintln!("kept for inspection: {}", self.0.display());
        } else {
            std::fs::remove_dir_all(&self.0).ok();
        }
    }
}

fn sha256_hex(bytes: &[u8]) -> String {
    use sha2::Digest;
    format!("{:x}", sha2::Sha256::digest(bytes))
}

/// A `$HOME` with the repo's policy installed and applied, so a binary run
/// under it loads the same policy the corpus was written against. The
/// `applied.json` record is written here directly, in the shape
/// `active::Applied` reads, because `ness policy apply` has no
/// non-interactive path by design. `ness` is copied into `.local/bin` when
/// given, for the shim tests: copied, not symlinked, because the guard
/// canonicalizes paths before matching `[control_plane]`, and a symlink
/// would make `~/.local/bin/ness` resolve to the build output (case 909).
/// `just ness-install` copies too.
fn fake_home(ness: Option<&Path>) -> TempHome {
    let home = temp_dir();
    let cfg = home.join(".config").join("ness");
    std::fs::create_dir_all(cfg.join("cases")).unwrap();
    let policy = std::fs::read(repo_root().join(".config/ness/policy.toml")).unwrap();
    std::fs::write(cfg.join("policy.toml"), &policy).unwrap();
    let mut cases = serde_json::Map::new();
    for (name, case) in load("corpus") {
        let bytes = serde_json::to_vec_pretty(&case).unwrap();
        std::fs::write(cfg.join("cases").join(&name), &bytes).unwrap();
        cases.insert(name, Value::String(sha256_hex(&bytes)));
    }
    let state = home.join(".local").join("state").join("ness");
    std::fs::create_dir_all(&state).unwrap();
    let applied = serde_json::json!({
        "policy_sha256": sha256_hex(&policy),
        "applied_at": "2026-01-01T00:00:00Z",
        "cases": cases,
    });
    std::fs::write(
        state.join("applied.json"),
        serde_json::to_string_pretty(&applied).unwrap(),
    )
    .unwrap();
    if let Some(ness) = ness {
        let bin_dir = home.join(".local").join("bin");
        std::fs::create_dir_all(&bin_dir).unwrap();
        std::fs::copy(ness, bin_dir.join("ness")).unwrap();
    }
    home
}

fn shim_path(shim: &str) -> PathBuf {
    let rel = match shim {
        "claude-bash" => ".claude/hooks/scripts/bash-guard.sh",
        "claude-write" => ".claude/hooks/scripts/write-guard.sh",
        "codex-bash" => ".codex/hooks/scripts/bash-guard.sh",
        "codex-write" => ".codex/hooks/scripts/write-guard.sh",
        "grok" => ".grok/scripts/harness-guard.sh",
        "crush" => ".config/crush/hooks/harness-guard.sh",
        "antigravity" => ".agents/harness/adapters/antigravity/scripts/harness-guard.sh",
        "cursor" => ".agents/harness/adapters/cursor/scripts/harness-guard.sh",
        other => panic!("unknown shim '{other}'"),
    };
    repo_root().join(rel)
}

fn run_shim(shim: &str, payload: &Value, home: &Path) -> (i32, Value, String) {
    let mut child = Command::new("bash")
        .arg(shim_path(shim))
        .current_dir(repo_root())
        .env("HOME", home)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .unwrap_or_else(|e| panic!("spawn shim {shim}: {e}"));
    let write_result = child
        .stdin
        .take()
        .expect("child stdin")
        .write_all(payload.to_string().as_bytes());
    if let Err(e) = write_result {
        if e.kind() != std::io::ErrorKind::BrokenPipe {
            panic!("write payload to {shim}: {e}");
        }
    }
    let output = child
        .wait_with_output()
        .unwrap_or_else(|e| panic!("wait for {shim}: {e}"));
    let stdout = String::from_utf8_lossy(&output.stdout);
    let parsed = if stdout.trim().is_empty() {
        Value::Null
    } else {
        serde_json::from_str(stdout.trim()).unwrap_or(Value::Null)
    };
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
    (output.status.code().unwrap_or(-1), parsed, stderr)
}

fn run_ok(cmd: &mut Command) {
    let status = cmd
        .status()
        .unwrap_or_else(|e| panic!("spawn {cmd:?}: {e}"));
    assert!(status.success(), "command failed: {cmd:?}");
}

fn run_capture_ok(cmd: &mut Command) -> String {
    let output = cmd
        .output()
        .unwrap_or_else(|e| panic!("spawn {cmd:?}: {e}"));
    assert!(
        output.status.success(),
        "command failed: {cmd:?}\nstderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    String::from_utf8_lossy(&output.stdout).trim().to_string()
}

/// Builds a 100-commit history on `main` via `git commit-tree`/`update-ref`
/// (no working-tree writes needed), so `main_branch_commit_warning`'s
/// `commits >= 100` threshold is met without 100 real commits.
fn init_main_branch_repo(repo: &Path) {
    std::fs::create_dir_all(repo).unwrap_or_else(|e| panic!("mkdir {}: {e}", repo.display()));
    run_ok(
        Command::new("git")
            .args(["init", "-q", "-b", "main"])
            .current_dir(repo),
    );
    let empty_tree = run_capture_ok(
        Command::new("git")
            .arg("mktree")
            .current_dir(repo)
            .stdin(Stdio::null()),
    );
    let mut prev: Option<String> = None;
    for i in 0..100 {
        let mut cmd = Command::new("git");
        cmd.arg("commit-tree")
            .arg(&empty_tree)
            .arg("-m")
            .arg(format!("commit {i}"));
        if let Some(p) = &prev {
            cmd.arg("-p").arg(p);
        }
        cmd.current_dir(repo)
            .env("GIT_AUTHOR_NAME", "ness-test")
            .env("GIT_AUTHOR_EMAIL", "ness-test@example.com")
            .env("GIT_COMMITTER_NAME", "ness-test")
            .env("GIT_COMMITTER_EMAIL", "ness-test@example.com");
        prev = Some(run_capture_ok(&mut cmd));
    }
    let last = prev.expect("at least one commit");
    run_ok(
        Command::new("git")
            .args(["update-ref", "refs/heads/main", &last])
            .current_dir(repo),
    );
    run_ok(
        Command::new("git")
            .args(["checkout", "-q", "main"])
            .current_dir(repo),
    );
}

#[test]
fn guard_corpus_matches_expected() {
    let home = fake_home(None);
    let mismatches = guard_mismatches(&built_ness(), &home);
    assert!(
        mismatches.is_empty(),
        "guard corpus mismatches:\n{}",
        mismatches.join("\n")
    );
}

#[test]
fn hook_corpus_matches_expected() {
    let built = built_ness();
    let home = fake_home(Some(&built));
    let mut mismatches = Vec::new();
    for (name, case) in load("hook_corpus") {
        let shim = case["shim"].as_str().expect("shim");
        let payload = &case["payload"];
        let expected = &case["expected"];
        let expected_exit = expected["exit"].as_i64().expect("exit") as i32;
        let expected_stdout = expected.get("stdout").cloned().unwrap_or(Value::Null);
        let (exit, stdout, stderr) = run_shim(shim, payload, &home);
        let mut bad = exit != expected_exit || stdout != expected_stdout;
        if let Some(expected_stderr) = expected.get("stderr").and_then(Value::as_str) {
            bad = bad || stderr != expected_stderr;
        }
        if bad {
            mismatches.push(format!(
                "{name}: expected exit {expected_exit} stdout {expected_stdout}; got exit {exit} stdout {stdout} stderr {stderr:?}"
            ));
        }
    }
    assert!(
        mismatches.is_empty(),
        "hook corpus mismatches:\n{}",
        mismatches.join("\n")
    );
}

#[test]
fn reshaped_corpus_matches_shims() {
    let built = built_ness();
    let home = fake_home(Some(&built));
    let mut mismatches = Vec::new();
    for (name, case) in load("corpus") {
        let harness = case["harness"].as_str().expect("harness");
        let tool = case["tool"].as_str().expect("tool");
        if !matches!(harness, "claude" | "codex") || !matches!(tool, "bash" | "write") {
            continue; // edit/multiedit/read: not a shim's contract.
        }
        let shim = format!("{harness}-{tool}");
        let payload = if tool == "bash" {
            serde_json::json!({
                "hook_event_name": "PreToolUse",
                "tool_name": "Bash",
                "tool_input": {"command": case["command"].as_str().unwrap_or("")},
            })
        } else {
            serde_json::json!({
                "hook_event_name": "PreToolUse",
                "tool_name": "Write",
                "tool_input": {
                    "file_path": case["path"].as_str().unwrap_or(""),
                    "content": case["content"].as_str().unwrap_or(""),
                },
            })
        };
        let expected_decision = case["expected"]["decision"].as_str().expect("decision");
        let expected_reason = case["expected"]["reason"].as_str().expect("reason");
        let expected_stdout = match expected_decision {
            "deny" => serde_json::json!({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": expected_reason,
                }
            }),
            "warn" if tool == "bash" => serde_json::json!({"systemMessage": expected_reason}),
            _ => Value::Null,
        };
        let (exit, stdout, _stderr) = run_shim(&shim, &payload, &home);
        if exit != 0 || stdout != expected_stdout {
            mismatches.push(format!(
                "{name} via {shim}: expected exit 0 stdout {expected_stdout}; got exit {exit} stdout {stdout}"
            ));
        }
    }
    assert!(
        mismatches.is_empty(),
        "reshaped corpus mismatches:\n{}",
        mismatches.join("\n")
    );
}

#[test]
fn shims_fail_closed_without_ness() {
    let home = fake_home(None);
    let mut mismatches = Vec::new();

    let bash_payload = serde_json::json!({"tool_input": {"command": "git status"}});
    for shim in ["claude-bash", "claude-write", "codex-bash", "codex-write"] {
        let (exit, stdout, _stderr) = run_shim(shim, &bash_payload, &home);
        let decision = stdout
            .pointer("/hookSpecificOutput/permissionDecision")
            .and_then(Value::as_str)
            .unwrap_or("");
        let reason = stdout
            .pointer("/hookSpecificOutput/permissionDecisionReason")
            .and_then(Value::as_str)
            .unwrap_or("");
        if exit != 0 || decision != "deny" || !reason.contains("not installed") {
            mismatches.push(format!("{shim}: exit {exit} stdout {stdout}"));
        }
    }

    let grok_payload = serde_json::json!({"toolInput": {"command": "git status"}});
    let (exit, stdout, _stderr) = run_shim("grok", &grok_payload, &home);
    let decision = stdout.get("decision").and_then(Value::as_str).unwrap_or("");
    let reason = stdout.get("reason").and_then(Value::as_str).unwrap_or("");
    if exit != 2 || decision != "deny" || !reason.contains("not installed") {
        mismatches.push(format!("grok: exit {exit} stdout {stdout}"));
    }

    let crush_payload = serde_json::json!({"tool_input": {"command": "git status"}});
    let (exit, stdout, stderr) = run_shim("crush", &crush_payload, &home);
    if exit != 2 || stdout != Value::Null || !stderr.contains("not installed") {
        mismatches.push(format!(
            "crush: exit {exit} stdout {stdout} stderr {stderr:?}"
        ));
    }

    let antigravity_payload = serde_json::json!({
        "toolCall": {"name": "run_command", "args": {"CommandLine": "git status"}},
    });
    let (exit, stdout, _stderr) = run_shim("antigravity", &antigravity_payload, &home);
    let decision = stdout.get("decision").and_then(Value::as_str).unwrap_or("");
    let reason = stdout.get("reason").and_then(Value::as_str).unwrap_or("");
    if exit != 0 || decision != "deny" || !reason.contains("not installed") {
        mismatches.push(format!("antigravity: exit {exit} stdout {stdout}"));
    }

    let cursor_payload = serde_json::json!({
        "tool_name": "Shell",
        "tool_input": {"command": "git status"},
    });
    let (exit, stdout, _stderr) = run_shim("cursor", &cursor_payload, &home);
    let permission = stdout
        .get("permission")
        .and_then(Value::as_str)
        .unwrap_or("");
    let message = stdout
        .get("user_message")
        .and_then(Value::as_str)
        .unwrap_or("");
    if exit != 0 || permission != "deny" || !message.contains("not installed") {
        mismatches.push(format!("cursor: exit {exit} stdout {stdout}"));
    }

    assert!(
        mismatches.is_empty(),
        "fail-closed mismatches:\n{}",
        mismatches.join("\n")
    );
}

#[test]
fn main_branch_commit_warning_forwards_cwd() {
    let built = built_ness();
    let home = fake_home(Some(&built));
    let repo = home.join("repo");
    init_main_branch_repo(&repo);
    let repo_str = repo.to_string_lossy().into_owned();
    let mut mismatches = Vec::new();

    let antigravity_payload = serde_json::json!({
        "toolCall": {
            "name": "run_command",
            "args": {"CommandLine": "git commit -m test", "Cwd": repo_str},
        },
        "workspacePaths": [repo_str],
    });
    let cursor_payload = serde_json::json!({
        "tool_name": "Shell",
        "tool_input": {"command": "git commit -m test"},
        "cwd": repo_str,
    });
    for (shim, payload) in [
        ("antigravity", &antigravity_payload),
        ("cursor", &cursor_payload),
    ] {
        let (exit, stdout, stderr) = run_shim(shim, payload, &home);
        if exit != 0
            || stdout != serde_json::json!({})
            || !stderr.contains("protected 'main' branch")
        {
            mismatches.push(format!(
                "{shim}: exit {exit} stdout {stdout} stderr {stderr:?}"
            ));
        }
    }

    let grok_payload = serde_json::json!({
        "toolName": "run_terminal_command",
        "toolInput": {"command": "git commit -m test"},
        "cwd": repo_str,
    });
    let (exit, stdout, stderr) = run_shim("grok", &grok_payload, &home);
    if exit != 0
        || stdout != serde_json::json!({"decision": "allow"})
        || !stderr.contains("protected 'main' branch")
    {
        mismatches.push(format!(
            "grok: exit {exit} stdout {stdout} stderr {stderr:?}"
        ));
    }

    let crush_payload = serde_json::json!({
        "tool_name": "run_terminal_command",
        "tool_input": {"command": "git commit -m test"},
        "cwd": repo_str,
    });
    let (exit, stdout, stderr) = run_shim("crush", &crush_payload, &home);
    if exit != 0 || stdout != Value::Null || !stderr.contains("protected 'main' branch") {
        mismatches.push(format!(
            "crush: exit {exit} stdout {stdout} stderr {stderr:?}"
        ));
    }

    assert!(
        mismatches.is_empty(),
        "main-branch cwd mismatches:\n{}",
        mismatches.join("\n")
    );
}

/// Checks the copy every harness hook actually execs
/// (`$HOME/.local/bin/ness`) against the corpus. Skipped unless
/// `NESS_CHECK_INSTALLED=1`, since a dev/CI box may not have run
/// `just ness-install` yet.
#[test]
fn installed_copy_matches_corpus() {
    if std::env::var_os("NESS_CHECK_INSTALLED").is_none() {
        eprintln!("skipped: set NESS_CHECK_INSTALLED=1 to check $HOME/.local/bin/ness");
        return;
    }
    let home = paths_home();
    let binary = home.join(".local").join("bin").join("ness");
    if !binary.exists() {
        panic!("{} not installed; run just ness-install", binary.display());
    }
    let mismatches = guard_mismatches(&binary, &home);
    assert!(
        mismatches.is_empty(),
        "installed ness mismatches:\n{}",
        mismatches.join("\n")
    );
}

#[test]
fn policy_check_reports_verdict_diff_and_case_delta() {
    let home = fake_home(None);
    let proposals = home.join(".local/state/ness/proposals/t");
    std::fs::create_dir_all(&proposals).unwrap();
    // Candidate: drop the credential-disclosure rule; cases 145/146 flip to allow.
    let text = std::fs::read_to_string(home.join(".config/ness/policy.toml")).unwrap();
    let candidate = text.replace(
        r"patterns = ['(?i)\bgh\s+auth\s+(?:token\b|git-credential\s+get\b|status\b[^;&|\n]*\s(?:--show-token\b|-[a-z]*t[a-z]*\b))']",
        "patterns = ['(?i)\\bgh\\s+auth\\s+never-matches-anything\\b']",
    );
    assert_ne!(candidate, text);
    std::fs::write(proposals.join("policy.toml"), candidate).unwrap();
    // Delete a case so the delta is non-empty.
    std::fs::remove_file(home.join(".config/ness/cases/147-allow-gh-auth-status.json")).unwrap();

    let out = Command::new(built_ness())
        .args([
            "policy",
            "check",
            proposals.join("policy.toml").to_str().unwrap(),
        ])
        .env("HOME", &home)
        .current_dir(repo_root())
        .output()
        .unwrap();
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert_eq!(out.status.code(), Some(1), "{stdout}");
    assert!(
        stdout.contains("145-deny-gh-auth-token.json: expected deny"),
        "{stdout}"
    );
    assert!(stdout.contains("verdict diff: 5 case(s)"), "{stdout}");
    assert!(
        stdout.contains("removed: 147-allow-gh-auth-status.json"),
        "{stdout}"
    );
}

#[test]
fn policy_apply_refuses_without_tty() {
    let home = fake_home(None);
    let out = Command::new(built_ness())
        .args([
            "policy",
            "apply",
            home.join(".config/ness/policy.toml").to_str().unwrap(),
        ])
        .env("HOME", &home)
        .stdin(std::process::Stdio::null())
        .output()
        .unwrap();
    assert_eq!(out.status.code(), Some(2));
    assert!(String::from_utf8_lossy(&out.stderr).contains("requires a terminal"));
}

#[test]
fn policy_active_prints_state() {
    let home = fake_home(None);
    let out = Command::new(built_ness())
        .args(["policy"])
        .env("HOME", &home)
        .output()
        .unwrap();
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(out.status.success(), "{stdout}");
    assert!(
        stdout.contains("verified: yes") && stdout.contains("commands.dangerous: 11"),
        "{stdout}"
    );
}

/// `--for-tests` once bypassed the TTY check; it must stay unknown so the
/// flag never silently returns.
#[test]
fn policy_apply_rejects_for_tests_flag() {
    let home = fake_home(None);
    let out = Command::new(built_ness())
        .args([
            "policy",
            "apply",
            "--for-tests",
            home.join(".config/ness/policy.toml").to_str().unwrap(),
        ])
        .env("HOME", &home)
        .stdin(std::process::Stdio::null())
        .output()
        .unwrap();
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert_eq!(out.status.code(), Some(2), "{stderr}");
    assert!(stderr.contains("unknown flag '--for-tests'"), "{stderr}");
}
