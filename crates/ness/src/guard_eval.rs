//! Shared decision path for both subcommands: safety policy plus the
//! generated-artifact override, matching `command_guard`'s wrapping of
//! `evaluate()` (`scripts/agent-harnesses.py:695-725`).

use crate::manifest::generated_path_warning;
use crate::policy::{self, GuardDecision};
use crate::policy_file::Compiled;
use std::path::Path;

pub fn evaluate_with_manifest(
    p: Result<&Compiled, &str>,
    tool: &str,
    command: &str,
    path: &str,
    content: &str,
    cwd: &str,
    manifest_path: &Path,
) -> GuardDecision {
    let p = match p {
        Ok(p) => p,
        Err(reason) => return GuardDecision::deny(reason),
    };
    let decision = policy::evaluate(p, tool, command, path, content, cwd);
    if decision.allowed() && !path.is_empty() {
        let warning = generated_path_warning(tool, path, manifest_path);
        if !warning.is_empty() {
            return GuardDecision::deny(warning);
        }
    }
    decision
}

/// The JSON verdict shape shared by `ness guard` and the normalized hook
/// modes (grok, crush, antigravity, cursor): `{harness, tool, decision,
/// reason}`.
pub fn verdict_json(harness: &str, tool: &str, decision: &GuardDecision) -> serde_json::Value {
    serde_json::json!({
        "harness": harness,
        "tool": tool,
        "decision": decision.decision,
        "reason": decision.reason,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn load_error_denies_bash_with_the_reason() {
        let d = evaluate_with_manifest(
            Err("policy not applied"),
            "bash",
            "ls",
            "",
            "",
            "",
            Path::new("/nonexistent"),
        );
        assert_eq!(d.decision, "deny");
        assert_eq!(d.reason, "policy not applied");
    }

    #[test]
    fn load_error_denies_harmless_write_with_the_reason() {
        let d = evaluate_with_manifest(
            Err("policy not applied"),
            "write",
            "",
            "/tmp/ness-guard-eval-harmless.txt",
            "x",
            "",
            Path::new("/nonexistent"),
        );
        assert_eq!(d.decision, "deny");
        assert_eq!(d.reason, "policy not applied");
    }
}
