//! Schema and loader for `~/.config/ness/policy.toml` (decision
//! 2026-10-17-ness-policy-as-data). Every pattern is a `fancy-regex`
//! expression transcribed verbatim from the former `policy.rs` statics. The
//! engine owns no pattern of its own; its onloy hardcoded policy is the
//! required control-plane coverage checked by `active::check_required_protection`.
//!
//! `parse` rejects unknown keys (`deny_unknown_fields`) so a typo in a table
//! name is a load error, not a silently empty rule set.

use fancy_regex::Regex;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Patterns {
    pub patterns: Vec<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Commands {
    pub privilege_escalation: Patterns,
    pub dangerous: Patterns,
    pub obfuscated: Patterns,
    pub credential_disclosure: Patterns,
    pub interactive_launch: Patterns,
    pub warn: Warn,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Warn {
    pub commit: String,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct WriteTargets {
    pub redirect: String,
    pub mutating_argv: String,
    pub sed_inplace: String,
    pub dd: String,
    pub path_token: String,
}

#[derive(Debug, Clone, Deserialize, PartialEq, Eq)]
#[serde(deny_unknown_fields)]
pub struct Modes {
    pub claude_default_mode: String,
    pub omp_approval_mode: String,
    pub opencode_edit: String,
    pub opencode_external_directory: String,
    pub opencode_webfetch: String,
}

#[derive(Debug, Clone, Deserialize, PartialEq, Eq)]
#[serde(deny_unknown_fields)]
pub struct ClaudeApproval {
    pub webfetch_domains: Vec<String>,
    pub tools: Vec<String>,
}

#[derive(Debug, Clone, Deserialize, PartialEq, Eq)]
#[serde(deny_unknown_fields)]
pub struct Approval {
    pub allow_prefix: Vec<String>,
    pub allow_exact: Vec<String>,
    pub prompt_prefix: Vec<String>,
    pub deny_prefix: Vec<String>,
    pub modes: Modes,
    pub claude: ClaudeApproval,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Policy {
    pub control_plane: Patterns,
    pub protected_paths: Patterns,
    pub secret_content: Patterns,
    pub commands: Commands,
    pub write_targets: WriteTargets,
    pub approval: Approval,
}

/// Compiled form consumed by `policy.rs`. Alternation tables that were one
/// regex in `policy.rs` (protected paths, secret content, control plane) are
/// joined with `|` here exactly as `CONTROL_PLANE_PATHS` already did, so a
/// one-entry list behaves identically to the old single pattern.
#[derive(Debug)]
pub struct Compiled {
    /// Compiled with an engine-side `(?i)` (as the old `CONTROL_PLANE_PATHS`
    /// static was) rather than per-entry flags: this table guards the guard's
    /// own inputs, so a policy edit must not be able to make it case-sensitive.
    pub control_plane: Regex,
    pub protected_paths: Regex,
    pub secret_content: Regex,
    pub privilege_escalation: Vec<Regex>,
    pub dangerous: Vec<Regex>,
    pub obfuscated: Vec<Regex>,
    pub credential_disclosure: Vec<Regex>,
    pub interactive_launch: Vec<Regex>,
    pub commit_command: Regex,
    pub redirect: Regex,
    pub mutating_argv: Regex,
    pub sed_inplace: Regex,
    pub dd: Regex,
    pub path_token: Regex,
    /// Entry counts per table, for `ness policy active`.
    pub counts: Vec<(&'static str, usize)>,
}

pub fn parse(text: &str) -> Result<Policy, String> {
    toml::from_str(text).map_err(|e| format!("policy.toml: {e}"))
}

fn compile_one(name: &str, pattern: &str) -> Result<Regex, String> {
    Regex::new(pattern).map_err(|e| format!("{name}: {e}"))
}

fn compile_list(name: &str, patterns: &[String]) -> Result<Vec<Regex>, String> {
    if patterns.is_empty() {
        return Err(format!("{name}: must list at least one pattern"));
    }
    patterns
        .iter()
        .enumerate()
        .map(|(i, p)| compile_one(&format!("{name}[{i}]"), p))
        .collect()
}

/// Joins entries as `(?:(?:a)|(?:b))`: each entry gets its own group so an
/// inline flag like `(?i)` in one entry cannot leak into the next.
fn compile_alternation(
    name: &str,
    patterns: &[String],
    case_insensitive: bool,
) -> Result<Regex, String> {
    if patterns.is_empty() {
        return Err(format!("{name}: must list at least one pattern"));
    }
    for (i, p) in patterns.iter().enumerate() {
        compile_one(&format!("{name}[{i}]"), p)?;
    }
    let groups: Vec<String> = patterns.iter().map(|p| format!("(?:{p})")).collect();
    let flag = if case_insensitive { "(?i)" } else { "" };
    let joined = format!("{flag}(?:{})", groups.join("|"));
    compile_one(name, &joined)
}

fn compile_with_span(name: &str, pattern: &str) -> Result<Regex, String> {
    let re = compile_one(name, pattern)?;
    if !re.capture_names().flatten().any(|n| n == "span") {
        return Err(format!("{name}: pattern must define a (?P<span>...) group"));
    }
    Ok(re)
}

impl Policy {
    pub fn compile(self) -> Result<Compiled, String> {
        let c = &self.commands;
        let w = &self.write_targets;
        let counts = vec![
            ("control_plane", self.control_plane.patterns.len()),
            ("protected_paths", self.protected_paths.patterns.len()),
            ("secret_content", self.secret_content.patterns.len()),
            (
                "commands.privilege_escalation",
                c.privilege_escalation.patterns.len(),
            ),
            ("commands.dangerous", c.dangerous.patterns.len()),
            ("commands.obfuscated", c.obfuscated.patterns.len()),
            (
                "commands.credential_disclosure",
                c.credential_disclosure.patterns.len(),
            ),
            (
                "commands.interactive_launch",
                c.interactive_launch.patterns.len(),
            ),
            ("approval.allow_prefix", self.approval.allow_prefix.len()),
            ("approval.allow_exact", self.approval.allow_exact.len()),
            ("approval.prompt_prefix", self.approval.prompt_prefix.len()),
            ("approval.deny_prefix", self.approval.deny_prefix.len()),
        ];
        Ok(Compiled {
            control_plane: compile_alternation(
                "control_plane",
                &self.control_plane.patterns,
                true,
            )?,
            protected_paths: compile_alternation(
                "protected_paths",
                &self.protected_paths.patterns,
                false,
            )?,
            secret_content: compile_alternation(
                "secret_content",
                &self.secret_content.patterns,
                false,
            )?,
            privilege_escalation: compile_list(
                "commands.privilege_escalation",
                &c.privilege_escalation.patterns,
            )?,
            dangerous: compile_list("commands.dangerous", &c.dangerous.patterns)?,
            obfuscated: compile_list("commands.obfuscated", &c.obfuscated.patterns)?,
            credential_disclosure: compile_list(
                "commands.credential_disclosure",
                &c.credential_disclosure.patterns,
            )?,
            interactive_launch: compile_list(
                "commands.interactive_launch",
                &c.interactive_launch.patterns,
            )?,
            commit_command: compile_one("commands.warn.commit", &c.warn.commit)?,
            redirect: compile_with_span("write_targets.redirect", &w.redirect)?,
            mutating_argv: compile_with_span("write_targets.mutating_argv", &w.mutating_argv)?,
            sed_inplace: compile_with_span("write_targets.sed_inplace", &w.sed_inplace)?,
            dd: compile_with_span("write_targets.dd", &w.dd)?,
            path_token: compile_one("write_targets.path_token", &w.path_token)?,
            counts,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fixture() -> String {
        std::fs::read_to_string(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/policy.toml"
        ))
        .unwrap()
    }

    #[test]
    fn real_policy_compiles() {
        let path = concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../../.config/ness/policy.toml"
        );
        let text = std::fs::read_to_string(path).unwrap();
        parse(&text).unwrap().compile().unwrap();
    }

    #[test]
    fn parses_and_compiles_fixture() {
        let p = parse(&fixture()).unwrap();
        assert_eq!(p.approval.allow_prefix, vec!["git status"]);
        assert_eq!(p.approval.modes.omp_approval_mode, "write");
        let c = p.compile().unwrap();
        assert_eq!(c.dangerous.len(), 2);
    }

    #[test]
    fn rejects_unknown_table() {
        let text = format!("{}\n[bogus]\nx = 1\n", fixture());
        let err = parse(&text).unwrap_err();
        assert!(err.contains("bogus"), "{err}");
    }

    #[test]
    fn rejects_uncompilable_pattern() {
        let text = fixture().replace(r"'(?i)\beval\s+.*\$'", "'(unclosed'");
        let err = parse(&text).unwrap().compile().unwrap_err();
        assert!(err.contains("commands.obfuscated[0]"), "{err}");
    }

    #[test]
    fn rejects_write_target_without_span_group() {
        let text = fixture().replace("(?P<span>[^\\s;|&<>]+)", "([^\\s;|&<>]+)");
        let err = parse(&text).unwrap().compile().unwrap_err();
        assert!(
            err.contains("write_targets.redirect") && err.contains("span"),
            "{err}"
        );
    }

    #[test]
    fn alternation_isolates_inline_flags() {
        let re = compile_alternation("t", &["(?i)a".to_string(), "B".to_string()], false).unwrap();
        assert!(re.is_match("A").unwrap());
        assert!(re.is_match("B").unwrap());
        assert!(!re.is_match("b").unwrap());
    }

    #[test]
    fn control_plane_is_case_insensitive() {
        let c = parse(&fixture()).unwrap().compile().unwrap();
        assert!(c
            .control_plane
            .is_match("/Users/x/.Config/Ness/policy.toml")
            .unwrap());
    }

    #[test]
    fn rejects_empty_deny_class() {
        let text = fixture().replace(
            "[commands.dangerous]\npatterns = [",
            "[commands.dangerous]\npatterns = []\n#",
        );
        let err = parse(&text).unwrap().compile().unwrap_err();
        assert!(
            err.contains("commands.dangerous") && err.contains("at least one"),
            "{err}"
        );
    }

    #[test]
    fn rejects_uncompilable_alternation_entry_by_index() {
        let text = fixture().replace(r"'(?i)(\.env($|\.)|\.ssh/)'", "'(unclosed'");
        let err = parse(&text).unwrap().compile().unwrap_err();
        assert!(err.contains("protected_paths[0]"), "{err}");
    }
}
