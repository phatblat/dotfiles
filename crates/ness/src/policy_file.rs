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
pub use crate::shell::TargetRule;
pub use crate::shell::Unrecognized;
pub use crate::shell::Wrapper;
pub use crate::shell::LeadingOptions;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Shell {
    pub scratch_dirs: Vec<String>,
    pub sinks: Vec<String>,
    pub protected_env: Vec<String>,
    pub read_only: Vec<String>,
    pub allow_write: Vec<String>,
    pub path_writers: std::collections::BTreeMap<String, TargetRule>,
    pub write_flags: std::collections::BTreeMap<String, Vec<String>>,
    pub output_options: std::collections::BTreeMap<String, Vec<String>>,
    pub pipe_into: std::collections::BTreeMap<String, Vec<String>>,
    pub write_markers: std::collections::BTreeMap<String, Vec<String>>,
    pub wrappers: std::collections::BTreeMap<String, Wrapper>,
    pub leading_options: std::collections::BTreeMap<String, LeadingOptions>,
    pub unrecognized: Unrecognized,
    pub guarded: Vec<String>,
    pub trusted_dirs: Vec<String>,
}

/// Allow mode compares command names case-insensitively (macOS volumes fold
/// case, so `RM` runs /bin/rm): the engine lowercases the name it looks up, so
/// policy names are lowercased here. A path (`./.venv/bin/python`) is a
/// literal and keeps its case.
fn fold_name(name: &str) -> String {
    if name.contains('/') {
        name.to_string()
    } else {
        name.to_ascii_lowercase()
    }
}

/// An entry's first word is its command name.
fn fold_entry(mut words: Vec<String>) -> Vec<String> {
    words[0] = fold_name(&words[0]);
    words
}

/// `map` re-keyed by `fold_name`; two keys that differ only in case collide.
fn fold_keys<V>(
    table: &str,
    map: std::collections::BTreeMap<String, V>,
) -> Result<std::collections::BTreeMap<String, V>, String> {
    let mut out = std::collections::BTreeMap::new();
    for (k, v) in map {
        if out.insert(fold_name(&k), v).is_some() {
            return Err(format!("shell.{table}: duplicate name '{k}' (names are case-insensitive)"));
        }
    }
    Ok(out)
}

impl Shell {
    pub fn compile(self) -> Result<crate::shell::ShellPolicy, String> {
        // scratch_dirs non-empty
        if self.scratch_dirs.is_empty() {
            return Err("shell.scratch_dirs: must list at least one directory".to_string());
        }
        for (i, v) in self.scratch_dirs.iter().enumerate() {
            if !v.starts_with('/') {
                return Err(format!("shell.scratch_dirs[{i}]: '{v}' must be an absolute path"));
            }
        }
        for (i, v) in self.sinks.iter().enumerate() {
            if !v.starts_with('/') {
                return Err(format!("shell.sinks[{i}]: '{v}' must be an absolute path"));
            }
        }
        // read_only entries
        let mut read_only = Vec::new();
        for (i, v) in self.read_only.iter().enumerate() {
            let words: Vec<String> = v.split_whitespace().map(|s| s.to_string()).collect();
            if words.is_empty() {
                return Err(format!("shell.read_only[{i}]: empty entry"));
            }
            read_only.push(fold_entry(words));
        }
        let mut allow_write = Vec::new();
        for (i, v) in self.allow_write.iter().enumerate() {
            let words: Vec<String> = v.split_whitespace().map(|s| s.to_string()).collect();
            if words.is_empty() {
                return Err(format!("shell.allow_write[{i}]: empty entry"));
            }
            allow_write.push(fold_entry(words));
        }
        // protected_env validation
        for (i, v) in self.protected_env.iter().enumerate() {
            let name = v.trim_end_matches('*');
            if !name.chars().all(|c| c.is_alphanumeric() || c == '_') || name.is_empty() || !name.chars().next().unwrap().is_alphabetic() && name.chars().next().unwrap() != '_' {
                return Err(format!("shell.protected_env[{i}]: '{v}' is not a variable name"));
            }
            if v.ends_with('*') && v.len() == 1 {
                return Err(format!("shell.protected_env[{i}]: '{v}' is not a variable name"));
            }
        }
        // write_flags
        for (cmd, flags) in &self.write_flags {
            for (i, f) in flags.iter().enumerate() {
                if !f.starts_with('-') {
                    return Err(format!("shell.write_flags.{cmd}[{i}]: '{f}' must start with '-'"));
                }
            }
        }
        // wrappers
        for (name, w) in &self.wrappers {
            if name.split_whitespace().next().is_none() {
                return Err("shell.wrappers: empty name".to_string());
            }
            for (i, f) in w.value_options.iter().enumerate() {
                if !f.starts_with('-') {
                    return Err(format!("shell.wrappers.{name}.value_options[{i}]: '{f}' must start with '-'"));
                }
            }
            for (i, f) in w.prompt_options.iter().enumerate() {
                if !f.starts_with('-') {
                    return Err(format!("shell.wrappers.{name}.prompt_options[{i}]: '{f}' must start with '-'"));
                }
            }
            if !w.separator.is_empty() && w.separator != "--" {
                return Err(format!("shell.wrappers.{name}.separator: '{}' must be \"\" or \"--\"", w.separator));
            }
        }
        // output_options
        for (cmd, opts) in &self.output_options {
            for (i, f) in opts.iter().enumerate() {
                let short = f.len() == 2 && f.starts_with('-') && !f.starts_with("--");
                let long = f.len() > 2 && f.starts_with("--");
                if !short && !long {
                    return Err(format!("shell.output_options.{cmd}[{i}]: '{f}' must be -x or --long"));
                }
            }
        }
        // pipe_into: each sink is `interpreter [inline-code option ...]`
        let mut pipe_into = std::collections::BTreeMap::new();
        for (cmd, sinks) in &self.pipe_into {
            let mut compiled = Vec::new();
            for (i, s) in sinks.iter().enumerate() {
                let words: Vec<String> = s.split_whitespace().map(str::to_owned).collect();
                if words.is_empty() || words[0].starts_with('-') || words[0].contains('/') {
                    return Err(format!("shell.pipe_into.{cmd}[{i}]: '{s}' must start with one interpreter name"));
                }
                if let Some(w) = words[1..].iter().find(|w| !w.starts_with('-')) {
                    return Err(format!("shell.pipe_into.{cmd}[{i}]: '{w}' must start with '-'"));
                }
                compiled.push(fold_entry(words));
            }
            if pipe_into.insert(fold_name(cmd), compiled).is_some() {
                return Err(format!("shell.pipe_into: duplicate name '{cmd}' (names are case-insensitive)"));
            }
        }
        // write_markers
        for (cmd, markers) in &self.write_markers {
            for (i, m) in markers.iter().enumerate() {
                if m.is_empty() {
                    return Err(format!("shell.write_markers.{cmd}[{i}]: empty marker"));
                }
            }
        }
        // trusted_dirs
        let mut trusted_dirs = Vec::new();
        for (i, v) in self.trusted_dirs.iter().enumerate() {
            let bad = !(v.starts_with('/') || v.starts_with("~/"))
                || (v.len() > 1 && v.ends_with('/'));
            if bad {
                return Err(format!("shell.trusted_dirs[{i}]: '{v}' must be an absolute path or ~/path without a trailing '/'"));
            }
            trusted_dirs.push(match v.strip_prefix("~/") {
                Some(rest) => crate::paths::home_dir().join(rest),
                None => std::path::PathBuf::from(v),
            });
        }
        // guarded
        for (i, v) in self.guarded.iter().enumerate() {
            if v.is_empty() || v.contains(char::is_whitespace) || v.contains('/') {
                return Err(format!("shell.guarded[{i}]: '{v}' must be one command name without '/'"));
            }
        }
        // leading_options
        for cmd in self.leading_options.keys() {
            if cmd.split_whitespace().next().is_none() {
                return Err("shell.leading_options: empty name".to_string());
            }
        }
        for (cmd, lo) in &self.leading_options {
            for (i, f) in lo.flags.iter().enumerate() {
                if !f.starts_with('-') {
                    return Err(format!("shell.leading_options.{cmd}.flags[{i}]: '{f}' must start with '-'"));
                }
            }
            for (i, f) in lo.value_options.iter().enumerate() {
                if !f.starts_with('-') {
                    return Err(format!("shell.leading_options.{cmd}.value_options[{i}]: '{f}' must start with '-'"));
                }
            }
        }
        // Build ShellPolicy
        let scratch_dirs = self.scratch_dirs.iter().map(|s| std::path::PathBuf::from(s)).collect();
        let mut wrappers = std::collections::BTreeMap::new();
        for (k, w) in self.wrappers {
            let key = fold_entry(k.split_whitespace().map(str::to_owned).collect());
            if wrappers.insert(key, w).is_some() {
                return Err(format!("shell.wrappers: duplicate name '{k}'"));
            }
        }
        let mut leading_options = std::collections::BTreeMap::new();
        for (k, lo) in self.leading_options {
            let key = fold_entry(k.split_whitespace().map(str::to_owned).collect());
            if leading_options.insert(key, lo).is_some() {
                return Err(format!("shell.leading_options: duplicate name '{k}'"));
            }
        }
        let path_writers = fold_keys("path_writers", self.path_writers)?;
        let write_flags = fold_keys("write_flags", self.write_flags)?;
        let output_options = fold_keys("output_options", self.output_options)?;
        let write_markers = fold_keys("write_markers", self.write_markers)?;
        Ok(crate::shell::ShellPolicy {
            scratch_dirs,
            sinks: self.sinks,
            protected_env: self.protected_env,
            read_only,
            allow_write,
            path_writers,
            write_flags,
            output_options,
            pipe_into,
            write_markers,
            wrappers,
            leading_options,
            unrecognized: self.unrecognized,
            guarded: self.guarded.iter().map(|g| g.to_ascii_lowercase()).collect(),
            approved: std::collections::BTreeSet::new(),
            trusted_dirs,
        })
    }
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
    pub shell: Shell,
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
    pub shell: crate::shell::ShellPolicy,
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
            ("shell.read_only", self.shell.read_only.len()),
            ("shell.allow_write", self.shell.allow_write.len()),
            ("shell.path_writers", self.shell.path_writers.len()),
            ("shell.wrappers", self.shell.wrappers.len()),
            ("shell.scratch_dirs", self.shell.scratch_dirs.len()),
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
            shell: self.shell.compile()?,
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

    #[test]
    fn shell_command_names_are_lowercased_on_load() {
        let text = fixture()
            .replace("guarded = []", "guarded = [\"PlistBuddy\"]")
            .replace(
                "allow_write = [\"gh api\", \"git commit\"]",
                "allow_write = [\"GH api\", \"./.venv/bin/Python\"]",
            )
            .replace("rm = \"all\"", "RM = \"all\"")
            .replace("[shell.wrappers.env]", "[shell.wrappers.ENV]");
        let shell = parse(&text).unwrap().compile().unwrap().shell;
        assert!(shell.guarded.contains("plistbuddy"));
        assert_eq!(shell.allow_write[0], ["gh", "api"]);
        // A path is a literal and keeps its case.
        assert_eq!(shell.allow_write[1], ["./.venv/bin/Python"]);
        assert!(shell.path_writers.contains_key("rm"));
        assert!(shell.wrappers.contains_key(&vec!["env".to_string()]));
    }

    #[test]
    fn rejects_command_names_that_differ_only_in_case() {
        let text = fixture().replace("rm = \"all\"", "rm = \"all\"\nRM = \"last\"");
        let err = parse(&text).unwrap().compile().unwrap_err();
        assert!(
            err.contains("shell.path_writers") && err.contains("duplicate"),
            "{err}"
        );
    }
}
