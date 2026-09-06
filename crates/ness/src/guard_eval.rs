//! Shared decision path for both subcommands: safety policy plus the
//! generated-artifact override, matching `command_guard`'s wrapping of
//! `evaluate()` (`scripts/agent-harnesses.py:695-725`).

use crate::manifest::generated_path_warning;
use crate::policy::{self, GuardDecision};
use std::path::Path;

pub fn evaluate_with_manifest(
    tool: &str,
    command: &str,
    path: &str,
    content: &str,
    cwd: &str,
    manifest_path: &Path,
) -> GuardDecision {
    let decision = policy::evaluate(tool, command, path, content, cwd);
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
