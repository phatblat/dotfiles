//! Sole implementation of the shared harness safety policy. Every pattern
//! lives in `~/.config/ness/policy.toml` (decision
//! 2026-10-17-ness-policy-as-data), compiled by `policy_file.rs` and loaded
//! by `active.rs`. This module is the engine only: the order of checks and
//! the reasons each produces.
//!
//! `fancy-regex` can error at match time on a backtracking blow-up. That is
//! treated as a deny (`policy pattern error`), never as "no match": a guard
//! whose pattern cannot run must not fall open.

use crate::policy_file::Compiled;
use fancy_regex::Regex;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GuardDecision {
    pub decision: String,
    pub reason: String,
}

impl GuardDecision {
    pub fn allow() -> Self {
        Self {
            decision: "allow".to_string(),
            reason: String::new(),
        }
    }

    pub fn warn(reason: impl Into<String>) -> Self {
        Self {
            decision: "warn".to_string(),
            reason: reason.into(),
        }
    }

    pub fn prompt(reason: impl Into<String>) -> Self {
        Self {
            decision: "prompt".to_string(),
            reason: reason.into(),
        }
    }

    pub fn deny(reason: impl Into<String>) -> Self {
        Self {
            decision: "deny".to_string(),
            reason: reason.into(),
        }
    }

    pub fn allowed(&self) -> bool {
        matches!(self.decision.as_str(), "allow" | "warn" | "prompt")
    }
}

/// A pattern that errors at match time is reported, and every caller turns
/// the error into a deny.
fn matches(re: &Regex, text: &str) -> Result<bool, String> {
    re.is_match(text)
        .map_err(|e| format!("policy pattern error: {e}"))
}

fn any_matches(res: &[Regex], text: &str) -> Result<bool, String> {
    for re in res {
        if matches(re, text)? {
            return Ok(true);
        }
    }
    Ok(false)
}

pub fn is_interactive_launch(p: &Compiled, command: &str) -> Result<bool, String> {
    any_matches(&p.interactive_launch, command)
}

/// Port of `evaluate` (safety.py:124-139).
pub fn evaluate(
    p: &Compiled,
    tool: &str,
    command: &str,
    path: &str,
    content: &str,
    cwd: &str,
) -> GuardDecision {
    let normalized_tool = tool.to_lowercase();
    let result = match normalized_tool.trim() {
        "bash" | "shell" | "exec" => evaluate_command(p, command, cwd),
        "write" | "edit" | "file_write" | "file_edit" => evaluate_write(p, path, content),
        _ => Ok(GuardDecision::allow()),
    };
    result.unwrap_or_else(GuardDecision::deny)
}

/// Port of `evaluate_command` (safety.py:142-174).
pub fn evaluate_command(p: &Compiled, command: &str, cwd: &str) -> Result<GuardDecision, String> {
    if command.trim().is_empty() {
        return Ok(GuardDecision::allow());
    }
    if any_matches(&p.privilege_escalation, command)? {
        return Ok(GuardDecision::deny("Privilege escalation blocked"));
    }
    if any_matches(&p.dangerous, command)? {
        return Ok(GuardDecision::deny("Dangerous command pattern detected"));
    }
    if any_matches(&p.obfuscated, command)? {
        return Ok(GuardDecision::deny("Obfuscated execution pattern detected"));
    }
    if any_matches(&p.credential_disclosure, command)? {
        return Ok(GuardDecision::deny("Credential disclosure blocked"));
    }
    let target = writes_to(p, command, &p.protected_paths)?;
    if !target.is_empty() {
        return Ok(GuardDecision::deny(format!(
            "protected file blocked: {target}"
        )));
    }
    let target = writes_to(p, command, &p.control_plane)?;
    if !target.is_empty() {
        return Ok(GuardDecision::deny(format!(
            "control-plane file is human-only: {target}. It decides what the guard permits, so edit it directly rather than through an agent."
        )));
    }
    if matches(&p.secret_content, command)? {
        return Ok(GuardDecision::deny("secret-like content detected"));
    }
    if let Some(reason) = crate::shell::classify(&p.shell, command, cwd) {
        return Ok(GuardDecision::prompt(reason));
    }
    let warning = main_branch_commit_warning(p, command, cwd)?;
    if !warning.is_empty() {
        return Ok(GuardDecision::warn(warning));
    }
    Ok(GuardDecision::allow())
}

/// Port of `evaluate_write` (safety.py:177-192).
pub fn evaluate_write(p: &Compiled, path: &str, content: &str) -> Result<GuardDecision, String> {
    if !path.is_empty() {
        let normalized = crate::paths::normalize_str(path);
        if matches(&p.protected_paths, &normalized)? {
            return Ok(GuardDecision::deny(format!(
                "protected file blocked: {path}"
            )));
        }
        if matches(&p.control_plane, &normalized)? {
            return Ok(GuardDecision::deny(format!(
                "control-plane file is human-only: {path}. It decides what the guard permits, so edit it directly rather than through an agent."
            )));
        }
    }
    if !content.is_empty() && matches(&p.secret_content, content)? {
        return Ok(GuardDecision::deny("secret-like content detected"));
    }
    Ok(GuardDecision::allow())
}

/// Port of `candidate_write_targets` (safety.py:210-224).
pub fn candidate_write_targets(p: &Compiled, command: &str) -> Result<Vec<String>, String> {
    let mut targets: Vec<String> = Vec::new();
    for pattern in [&p.redirect, &p.mutating_argv, &p.sed_inplace, &p.dd] {
        for caps in pattern.captures_iter(command) {
            let caps = caps.map_err(|e| format!("policy pattern error: {e}"))?;
            let Some(span) = caps.name("span") else {
                continue;
            };
            for tok in p.path_token.find_iter(span.as_str()) {
                let tok = tok.map_err(|e| format!("policy pattern error: {e}"))?;
                targets.push(tok.as_str().to_string());
            }
        }
    }
    Ok(targets
        .into_iter()
        .map(|t| t.trim_matches(|c| c == '\'' || c == '"').to_string())
        .filter(|t| !t.is_empty())
        .collect())
}

/// Port of `writes_to` (safety.py:227-233).
pub fn writes_to(p: &Compiled, command: &str, pattern: &Regex) -> Result<String, String> {
    for target in candidate_write_targets(p, command)? {
        if matches(pattern, &crate::paths::normalize_str(&target))? {
            return Ok(target);
        }
    }
    Ok(String::new())
}

/// Port of `main_branch_commit_warning` (safety.py:244-266). `cwd == ""`
/// falls back to the real process cwd, matching Python's `cwd or
/// os.getcwd()` — distinct from the CLI layer's default of `find_root()`
/// when `--cwd` is omitted entirely (`parse_guard_args`' `"cwd": str(ROOT)`).
pub fn main_branch_commit_warning(
    p: &Compiled,
    command: &str,
    cwd: &str,
) -> Result<String, String> {
    if !matches(&p.commit_command, command)? {
        return Ok(String::new());
    }

    let workdir = if cwd.is_empty() {
        std::env::current_dir()
            .map(|p| p.to_string_lossy().into_owned())
            .unwrap_or_default()
    } else {
        cwd.to_string()
    };
    let workdir = workdir.as_str();

    let branch = run_git(&["branch", "--show-current"], workdir);
    if branch != "main" && branch != "master" {
        return Ok(String::new());
    }

    let repo_root = run_git(&["rev-parse", "--show-toplevel"], workdir);
    let commit_count = run_git(&["rev-list", "--count", "HEAD"], workdir);
    let home = crate::paths::home_dir().to_string_lossy().into_owned();
    let commits: i64 = commit_count.parse().unwrap_or(0);

    if repo_root != home && commits >= 100 {
        return Ok(format!(
            "WARNING: You are on the protected '{branch}' branch. Create a feature branch before committing."
        ));
    }
    Ok(String::new())
}

/// Port of `run_git` (safety.py:269-284): 2s timeout, empty string on any
/// spawn failure, non-zero exit, or timeout.
pub fn run_git(args: &[&str], cwd: &str) -> String {
    use std::io::Read;
    use std::process::{Command, Stdio};
    use std::time::Duration;
    use wait_timeout::ChildExt;

    let mut child = match Command::new("git")
        .args(args)
        .current_dir(cwd)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
    {
        Ok(child) => child,
        Err(_) => return String::new(),
    };

    match child.wait_timeout(Duration::from_secs(2)) {
        Ok(Some(status)) => {
            if !status.success() {
                return String::new();
            }
            let mut buf = String::new();
            if let Some(mut stdout) = child.stdout.take() {
                let _ = stdout.read_to_string(&mut buf);
            }
            buf.trim().to_string()
        }
        Ok(None) => {
            let _ = child.kill();
            let _ = child.wait();
            String::new()
        }
        Err(_) => String::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn compiled() -> crate::policy_file::Compiled {
        let text = std::fs::read_to_string(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/policy.toml"
        ))
        .unwrap();
        crate::policy_file::parse(&text).unwrap().compile().unwrap()
    }

    #[test]
    fn evaluate_takes_policy() {
        let p = compiled();
        assert_eq!(evaluate(&p, "bash", "sudo ls", "", "", "").decision, "deny");
        assert_eq!(
            evaluate(&p, "bash", "ness policy apply x", "", "", "").decision,
            "deny"
        );
        assert_eq!(
            evaluate(&p, "write", "", "/Users/x/.config/ness/policy.toml", "", "").decision,
            "deny"
        );
        assert_eq!(evaluate(&p, "bash", "ls", "", "", "").decision, "allow");
    }

    #[test]
    fn regex_runtime_error_denies() {
        let mut p = compiled();
        // fancy-regex backtrack limit of 1 makes any match attempt error out.
        // The lookahead keeps the pattern on fancy-regex's backtracking VM
        // (a plain `(a+)+b` is delegated to `regex`, which never errors).
        p.dangerous = vec![fancy_regex::RegexBuilder::new(r"(?=a)(a+)+b")
            .backtrack_limit(1)
            .build()
            .unwrap()];
        let d = evaluate(&p, "bash", "aaaaaaaaaaaaaaaaaaaaaaaaaaaac", "", "", "");
        assert_eq!(d.decision, "deny");
        assert!(d.reason.starts_with("policy pattern error"), "{}", d.reason);
    }

    fn limited() -> Regex {
        fancy_regex::RegexBuilder::new(r"(?=a)(a+)+b")
            .backtrack_limit(1)
            .build()
            .unwrap()
    }

    #[test]
    fn write_target_pattern_error_denies() {
        let mut p = compiled();
        p.path_token = limited();
        let d = evaluate(&p, "bash", "echo > aaaaaaaaaaaaaaaaaaaaaaaaac", "", "", "");
        assert_eq!(d.decision, "deny");
        assert!(d.reason.starts_with("policy pattern error"), "{}", d.reason);
    }

    #[test]
    fn interactive_launch_pattern_error_is_err() {
        let mut p = compiled();
        p.interactive_launch = vec![limited()];
        let r = is_interactive_launch(&p, "aaaaaaaaaaaaaaaaaaaaaaaaac");
        assert!(r.is_err(), "{r:?}");
        assert!(r.unwrap_err().starts_with("policy pattern error"));
    }
}
