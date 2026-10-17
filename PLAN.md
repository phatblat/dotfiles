# ness policy as data — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every ness policy table and the harness approval baselines into `~/.config/ness/policy.toml`, loaded fail-closed and verified against a human-written `applied.json`, with `ness policy check|apply|active` as the proposal workflow.

**Decision:** 2026-10-17-ness-policy-as-data — Move the ness safety policy out of code into a TOML file (`docs/decisions/2026-10-17-ness-policy-as-data.md`)

**Architecture:** `policy_file.rs` parses and compiles the TOML into a `Compiled` struct; `active.rs` loads it from the fixed path, verifies its sha256 against `~/.local/state/ness/applied.json`, and enforces `REQUIRED_PROTECTION`; `policy.rs` keeps the evaluation logic but takes `&Compiled` instead of statics and turns regex runtime errors into deny; `policy_cmd.rs` implements `check`, `apply`, `active`. The 127 guard cases move to `.config/ness/cases/`. `harness_policy.py` keeps `bash_rules()` and reads `[approval]` from the same file.

**Tech Stack:** Rust 2021 (`fancy-regex` 0.19, `serde`, `serde_json`, new: `toml` 0.8, `sha2` 0.10), Python 3.11+ `tomllib`, `cargo test`, bats.

---

## Working conventions for every task

- Worktree root is `/Users/phatblat/.worktrees/dotfiles/ness-policy-as-data` (call it `$W`). Every path below is relative to `$W` unless it starts with `~` or `/`. Use absolute paths in tool calls.
- Rust commands run with `--manifest-path $W/crates/ness/Cargo.toml` (there is no workspace `Cargo.toml` at `$W`).
- Commit after each task with the exact pathspec shown. Append `Co-Authored-By: oh-my-pi <omp@can.ac>` after a blank line.
- **Do not run `just ness-install` before Task 9.** The installed `~/.local/bin/ness` is what every harness hook execs, including the omp session doing this work. A new binary that fails closed on a missing `~/.config/ness/policy.toml` denies every tool call on this machine. Task 9 bootstraps the real `$HOME` first.
- **Do not run `python3 scripts/harness-apply.py perms`.** It rewrites `~/.omp/agent/config.yml` and would overwrite the user's hand-written `rm` rules. Task 10 compares renderer output instead.
- The guard denies agent writes to `scripts/harness_policy.py` and everything under `crates/ness/`. Tasks that edit those files are marked **human-applied**: the worker writes the full file content to `~/.local/state/ness/proposals/<task>/<filename>` and reports the path; the human copies it into place and runs the task's verification. Everything else the worker edits directly.

---

### Task 0: Baseline artifacts for equivalence checks

**Files:**
- Create (untracked, outside repo): `/tmp/ness-baseline/ness`, `/tmp/ness-baseline/bash_rules.json`, `/tmp/ness-baseline/latency.txt`

- [ ] **Step 1: Build the pre-change binary and keep it**

```bash
cargo build --release --manifest-path $W/crates/ness/Cargo.toml
mkdir -p /tmp/ness-baseline
cp $W/crates/ness/target/release/ness /tmp/ness-baseline/ness
```

Expected: `/tmp/ness-baseline/ness guard --harness claude --tool bash --command 'ls'` prints `{"decision":"allow","harness":"claude","reason":"","tool":"bash"}`.

- [ ] **Step 2: Snapshot every `bash_rules` rendering and the mode constants**

```bash
cd $W && python3 - <<'PY' > /tmp/ness-baseline/bash_rules.json
import json, sys
sys.path.insert(0, "scripts")
import harness_policy as h
out = {s: h.bash_rules(s) for s in ("claude", "claude-deny", "antigravity", "opencode", "omp")}
out["modes"] = {
    "claude_default_mode": h.CLAUDE_DEFAULT_MODE,
    "omp_approval_mode": h.OMP_APPROVAL_MODE,
    "opencode_edit": h.OPENCODE_EDIT,
    "opencode_external_directory": h.OPENCODE_EXTERNAL_DIRECTORY,
    "opencode_webfetch": h.OPENCODE_WEBFETCH,
}
out["claude"] = {"rules": out["claude"]}
json.dump(out, sys.stdout, indent=2, sort_keys=True)
PY
```

Expected: a JSON file with keys `antigravity`, `claude`, `claude-deny`, `modes`, `omp`, `opencode`.

- [ ] **Step 3: Measure baseline guard latency**

```bash
cd $W && for i in $(seq 1 200); do /tmp/ness-baseline/ness guard --harness claude --tool bash --command 'git status' >/dev/null; done
cd $W && python3 - <<'PY' | tee /tmp/ness-baseline/latency.txt
import subprocess, time, statistics
t=[]
for _ in range(200):
    s=time.perf_counter()
    subprocess.run(["/tmp/ness-baseline/ness","guard","--harness","claude","--tool","bash","--command","git status"],capture_output=True)
    t.append((time.perf_counter()-s)*1000)
t.sort(); print(f"baseline p50={t[100]:.2f}ms p95={t[190]:.2f}ms")
PY
```

Expected: a line like `baseline p50=3.1ms p95=4.0ms`. No commit for this task.

---

### Task 1: Policy file schema and loader

**Files:**
- Modify: `crates/ness/Cargo.toml` (dependencies)
- Create: `crates/ness/src/policy_file.rs`
- Create: `crates/ness/tests/fixtures/policy.toml` (minimal fixture for unit tests)

**Human-applied** (under `crates/ness/`).

- [ ] **Step 1: Add dependencies**

In `crates/ness/Cargo.toml` `[dependencies]` add:

```toml
sha2 = "0.10"
toml = "0.8"
```

- [ ] **Step 2: Write the fixture policy**

`crates/ness/tests/fixtures/policy.toml`:

```toml
# Minimal fixture for engine unit tests. The real policy is ~/.config/ness/policy.toml.
[control_plane]
patterns = ['/\.config/ness/policy\.toml(?![\w.-])', '/\.local/state/ness/applied\.json(?![\w.-])', '/\.local/bin/ness(?![\w.-])']

[protected_paths]
patterns = ['(?i)(\.env($|\.)|\.ssh/)']

[secret_content]
patterns = ['(?i)(AKIA[0-9A-Z]{16})']

[commands.privilege_escalation]
patterns = ['(?i)(^|;|&&|\|\||\||\n|\r|\$\(|`)\s*(sudo|su|doas|pkexec)\b']

[commands.dangerous]
patterns = ['(?i)\brm\s+-(?=[A-Za-z-]*r)(?=[A-Za-z-]*f)[A-Za-z-]*\s+(/|~|\*|\.\.)', '(?i)\bness\s+policy\s+apply\b']

[commands.obfuscated]
patterns = ['(?i)\beval\s+.*\$']

[commands.credential_disclosure]
patterns = ['(?i)\bgh\s+auth\s+token\b']

[commands.interactive_launch]
patterns = ['^\s*bash\s*$']

[commands.warn]
commit = '^\s*(git\s+commit|git\s+-C\s+\S+\s+commit)\b'

[write_targets]
redirect = '>>?\s*(?P<span>[^\s;|&<>]+)'
mutating_argv = '(?i)\b(?:rm|mv|cp|tee|ln|install|truncate|shred|unlink|touch|chmod|chown)\b(?P<span>[^;|&]*)'
sed_inplace = '(?i)\bsed\b(?P<span>[^;|&]*?-i(?:\S*)?[^;|&]*)'
dd = '(?i)\bdd\b[^;|&]*?\bof=(?P<span>[^\s;|&]+)'
path_token = '''[^\s;|&<>'"]*[/~][^\s;|&<>'"]*'''

[approval]
allow_prefix = ["git status"]
allow_exact = ["pwd"]
prompt_prefix = ["rm"]
deny_prefix = ["sudo"]

[approval.modes]
claude_default_mode = "auto"
omp_approval_mode = "write"
opencode_edit = "ask"
opencode_external_directory = "ask"
opencode_webfetch = "ask"

[approval.claude]
webfetch_domains = ["github.com"]
tools = ["WebSearch"]
```

- [ ] **Step 3: Write the failing unit tests**

Append to the bottom of the new `crates/ness/src/policy_file.rs` (the module body comes in Step 5; write the tests first so Step 4 fails to compile):

```rust
#[cfg(test)]
mod tests {
    use super::*;

    fn fixture() -> String {
        std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/policy.toml")).unwrap()
    }

    #[test]
    fn parses_and_compiles_fixture() {
        let p = parse(&fixture()).unwrap();
        let c = p.compile().unwrap();
        assert_eq!(c.dangerous.len(), 2);
        assert_eq!(c.approval.allow_prefix, vec!["git status"]);
        assert_eq!(c.approval.modes.omp_approval_mode, "write");
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
        assert!(err.contains("write_targets.redirect") && err.contains("span"), "{err}");
    }
}
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml policy_file`
Expected: compile error, `parse` and `Compiled` not defined.

- [ ] **Step 5: Write the module**

Top of `crates/ness/src/policy_file.rs`, above the tests:

```rust
//! Schema and loader for `~/.config/ness/policy.toml` (decision
//! 2026-10-17-ness-policy-as-data). Every pattern is a `fancy-regex`
//! expression transcribed verbatim from the former `policy.rs` statics; the
//! engine owns no pattern of its own except `active::REQUIRED_PROTECTION`.
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
pub struct Compiled {
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
    pub approval: Approval,
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
    patterns
        .iter()
        .enumerate()
        .map(|(i, p)| compile_one(&format!("{name}[{i}]"), p))
        .collect()
}

fn compile_alternation(name: &str, patterns: &[String]) -> Result<Regex, String> {
    if patterns.is_empty() {
        return Err(format!("{name}: must list at least one pattern"));
    }
    for (i, p) in patterns.iter().enumerate() {
        compile_one(&format!("{name}[{i}]"), p)?;
    }
    let joined = format!("(?:{})", patterns.join("|"));
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
            ("commands.privilege_escalation", c.privilege_escalation.patterns.len()),
            ("commands.dangerous", c.dangerous.patterns.len()),
            ("commands.obfuscated", c.obfuscated.patterns.len()),
            ("commands.credential_disclosure", c.credential_disclosure.patterns.len()),
            ("commands.interactive_launch", c.interactive_launch.patterns.len()),
            ("approval.allow_prefix", self.approval.allow_prefix.len()),
            ("approval.allow_exact", self.approval.allow_exact.len()),
            ("approval.prompt_prefix", self.approval.prompt_prefix.len()),
            ("approval.deny_prefix", self.approval.deny_prefix.len()),
        ];
        Ok(Compiled {
            control_plane: compile_alternation("control_plane", &self.control_plane.patterns)?,
            protected_paths: compile_alternation("protected_paths", &self.protected_paths.patterns)?,
            secret_content: compile_alternation("secret_content", &self.secret_content.patterns)?,
            privilege_escalation: compile_list("commands.privilege_escalation", &c.privilege_escalation.patterns)?,
            dangerous: compile_list("commands.dangerous", &c.dangerous.patterns)?,
            obfuscated: compile_list("commands.obfuscated", &c.obfuscated.patterns)?,
            credential_disclosure: compile_list("commands.credential_disclosure", &c.credential_disclosure.patterns)?,
            interactive_launch: compile_list("commands.interactive_launch", &c.interactive_launch.patterns)?,
            commit_command: compile_one("commands.warn.commit", &c.warn.commit)?,
            redirect: compile_with_span("write_targets.redirect", &w.redirect)?,
            mutating_argv: compile_with_span("write_targets.mutating_argv", &w.mutating_argv)?,
            sed_inplace: compile_with_span("write_targets.sed_inplace", &w.sed_inplace)?,
            dd: compile_with_span("write_targets.dd", &w.dd)?,
            path_token: compile_one("write_targets.path_token", &w.path_token)?,
            approval: self.approval.clone(),
            counts,
        })
    }
}
```

Add `mod policy_file;` to `crates/ness/src/main.rs` after `mod policy;`.

- [ ] **Step 6: Run tests to verify they pass**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml policy_file`
Expected: `test result: ok. 4 passed`.

- [ ] **Step 7: Commit**

```bash
git -C $W add crates/ness/Cargo.toml crates/ness/Cargo.lock crates/ness/src/policy_file.rs crates/ness/src/main.rs crates/ness/tests/fixtures/policy.toml
git -C $W commit -m "feat(ness): parse and compile policy.toml" -- crates/ness/Cargo.toml crates/ness/Cargo.lock crates/ness/src/policy_file.rs crates/ness/src/main.rs crates/ness/tests/fixtures/policy.toml
```

---

### Task 2: The real policy file

**Files:**
- Create: `.config/ness/policy.toml`

The worker edits this directly: it is not yet control plane for the installed binary (that happens when Task 9 installs the new one). Verification of the transcription is Task 5's corpus run; this task only checks it parses.

- [ ] **Step 1: Generate the `[approval]` block from the Python constants**

Run this and keep the output for Step 2:

```bash
cd $W && python3 - <<'PY' > /tmp/ness-baseline/approval.toml
import sys
sys.path.insert(0, "scripts")
import harness_policy as h
def arr(xs): return "[" + ", ".join('"' + x.replace("\\", "\\\\").replace('"', '\\"') + '"' for x in xs) + "]"
print("[approval]")
print("allow_prefix =", arr(h.BASH_ALLOW_PREFIX))
print("allow_exact =", arr(h.BASH_ALLOW_EXACT))
print("prompt_prefix =", arr(h.BASH_ASK_PREFIX))
print("deny_prefix =", arr(h.BASH_DENY_PREFIX))
print()
print("[approval.modes]")
print(f'claude_default_mode = "{h.CLAUDE_DEFAULT_MODE}"')
print(f'omp_approval_mode = "{h.OMP_APPROVAL_MODE}"')
print(f'opencode_edit = "{h.OPENCODE_EDIT}"')
print(f'opencode_external_directory = "{h.OPENCODE_EXTERNAL_DIRECTORY}"')
print(f'opencode_webfetch = "{h.OPENCODE_WEBFETCH}"')
print()
print("[approval.claude]")
print("webfetch_domains =", arr(h.WEBFETCH_ALLOW_DOMAINS))
print("tools =", arr(h.CLAUDE_TOOL_ALLOW))
PY
cat /tmp/ness-baseline/approval.toml | head -3
```

Expected: first line `[approval]`, second line starts `allow_prefix = ["[", "awk", "basename",`.

- [ ] **Step 2: Write the file**

`.config/ness/policy.toml` is the content below, followed by a blank line and the entire contents of `/tmp/ness-baseline/approval.toml`. The regex sections are transcribed verbatim from `crates/ness/src/policy.rs` lines 72-184 at commit `4a60c1b`; do not simplify any pattern.

```toml
# ness safety policy — decision 2026-10-17-ness-policy-as-data.
#
# Every pattern is a fancy-regex expression in a TOML literal string ('...'
# or '''...'''); no escaping is applied by TOML, so write the regex exactly.
# This file is control plane: the guard denies agent writes to it, and the
# binary refuses to run it until a human has run `ness policy apply`.
#
# To change policy: write a candidate to ~/.local/state/ness/proposals/<slug>/policy.toml,
# add cases under ~/.config/ness/cases/, run `ness policy check <candidate>`,
# then a human runs `ness policy apply <candidate>`.

# Paths the guard denies agent writes to. Each entry is pinned by a 9xx case.
[control_plane]
patterns = [
  '/\.agents/harness/hooks/',
  '/\.agents/harness/self-improve-policy\.json(?![\w.-])',
  '/\.agents/harness/generated-paths\.json(?![\w.-])',
  '/scripts/agent-harnesses\.py(?![\w.-])',
  '/scripts/agent_plugins\.py(?![\w.-])',
  '/scripts/harness_policy\.py(?![\w.-])',
  '/harness-guard\.(?:py|sh|ts)(?![\w.-])',
  '/(?:write|bash)-guard\.sh(?![\w.-])',
  '/opencode/plugins/harness\.ts(?![\w.-])',
  '/agent/extensions/harness\.ts(?![\w.-])',
  '/harness-guard\.json(?![\w.-])',
  '/crates/ness/(?!target(?:/|$))',
  # The policy itself and the record of the last human apply (REQUIRED_PROTECTION).
  '/\.config/ness/policy\.toml(?![\w.-])',
  '/\.local/state/ness/applied\.json(?![\w.-])',
  '/\.local/bin/ness(?![\w.-])',
]

# Secrets on disk: never written by an agent, through any tool or shell.
[protected_paths]
patterns = [
  '(?i)(\.env($|\.)|\.ssh/|id_(rsa|ed25519|ecdsa)|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|\.aws/credentials|\.docker/config\.json|kubeconfig|\.npmrc$|\.pypirc$|\.netrc$|\.pgpass$|\.htpasswd$|\.git-credentials|\.claude/\.credentials\.json|\.codex/auth\.json|\.omp/agent/agent\.db|\.omp/agent/secrets\.yml|\.pi/agent/auth\.json|\.gemini/google_accounts\.json|\.gemini/oauth_creds\.json|\.gemini/antigravity-cli/installation_id|\.gemini/antigravity-cli/conversations/|\.cursor/ai-tracking/|\.grok/auth\.json|\.grok/mcp_credentials\.json|\.config/crush/crush\.json|\.local/share/crush/crush\.json|\.local/share/crush/crush\.db)',
]

# Secret-shaped content in anything written, including heredocs in shell commands.
[secret_content]
patterns = [
  '''(?i)(AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|glpat-[A-Za-z0-9_-]{20,}|xox[bpoas]-[A-Za-z0-9-]+|-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----|password\s*[:=]\s*["'][^"']{8,}["'])''',
]

[commands.privilege_escalation]
patterns = ['(?i)(^|;|&&|\|\||\||\n|\r|\$\(|`)\s*(sudo|su|doas|pkexec)\b']

[commands.dangerous]
patterns = [
  '(?i)\brm\s+-(?=[A-Za-z-]*r)(?=[A-Za-z-]*f)[A-Za-z-]*\s+(/|~|\*|\.\.)',
  '(?i)>\s*/dev/sd[a-z]?',
  '(?i)\bmkfs(\.|\s)',
  '(?i)\bdd\s+if=.*\s+of=/dev/',
  '(?i)\bchmod\s+(-R\s+)?777\b',
  '(?i)\bchmod\s+\+s\b',
  '(?i):\(\)\{.*:\|:&\};',
  '(?i)\b(curl|wget)\b[^|]*\|\s*(ba)?sh\b',
  '(?i)\b(truncate|shred)\b',
  # Only a human at a terminal applies policy (REQUIRED_PROTECTION).
  '(?i)\bness\s+policy\s+apply\b',
]

[commands.obfuscated]
patterns = [
  '(?i)\beval\s+.*\$',
  '(?i)\bbase64\s+-d.*\|\s*(ba)?sh\b',
  '(?i)\bawk\s+.*system\s*\(',
  '(?i)\bbash\s+<\(',
]

# `gh auth token` / `gh auth status --show-token` print the stored credential.
[commands.credential_disclosure]
patterns = ['(?i)\bgh\s+auth\s+(?:token\b|status\b[^;&|\n]*\s(?:--show-token|-t)\b)']

# Codex `unified_exec` keeps a launched process open and `write_stdin` never
# re-runs PreToolUse, so a bare interactive shell/REPL launch would let every
# later command bypass the guard.
[commands.interactive_launch]
patterns = ['^\s*(?:(?:env|exec|command)\s+)?(?:\S*/)?(?:bash|zsh|sh|dash|ksh|fish|nu|python3?(?:\.\d+)?|node|bun|deno|irb|ruby|lua|psql|sqlite3|mysql|redis-cli)(?:\s+repl)?(?:\s+--?(?:i|l|q|login|interactive|norc|noprofile|quiet))*\s*$']

# Deliberately case-sensitive (matches the original Python source).
[commands.warn]
commit = '^\s*(git\s+commit|git\s+-C\s+\S+\s+commit)\b'

# How the guard finds the paths a shell command writes to. Each entry except
# path_token must define a (?P<span>...) group.
[write_targets]
redirect = '>>?\s*(?P<span>[^\s;|&<>]+)'
mutating_argv = '(?i)\b(?:rm|mv|cp|tee|ln|install|truncate|shred|unlink|touch|chmod|chown)\b(?P<span>[^;|&]*)'
sed_inplace = '(?i)\bsed\b(?P<span>[^;|&]*?-i(?:\S*)?[^;|&]*)'
dd = '(?i)\bdd\b[^;|&]*?\bof=(?P<span>[^\s;|&]+)'
path_token = '''[^\s;|&<>'"]*[/~][^\s;|&<>'"]*'''

# Per-harness approval baselines rendered by scripts/harness_policy.py
# (`bash_rules(style)`): allow lists, prompt-even-in-yolo, absolute deny.
```

- [ ] **Step 3: Verify it parses and compiles with the Task 1 loader**

Add this test to the `tests` module in `crates/ness/src/policy_file.rs` (**human-applied**):

```rust
    #[test]
    fn real_policy_compiles() {
        let path = concat!(env!("CARGO_MANIFEST_DIR"), "/../../.config/ness/policy.toml");
        let text = std::fs::read_to_string(path).unwrap();
        let c = parse(&text).unwrap().compile().unwrap();
        assert_eq!(c.dangerous.len(), 10);
        assert_eq!(c.control_plane.as_str().matches("ness/policy").count(), 1);
    }
```

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml real_policy_compiles`
Expected: `1 passed`.

- [ ] **Step 4: Commit**

```bash
git -C $W add .config/ness/policy.toml crates/ness/src/policy_file.rs
git -C $W commit -m "feat(ness): add policy.toml transcribed from policy.rs" -- .config/ness/policy.toml crates/ness/src/policy_file.rs
```

---

### Task 3: Evaluate against a `Compiled` policy, fail closed on regex errors

**Files:**
- Modify: `crates/ness/src/policy.rs:1-184` (delete statics and `matches`), `:186-301` (thread `&Compiled`)

**Human-applied.**

- [ ] **Step 1: Write the failing unit test**

Append to `crates/ness/src/policy.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    fn compiled() -> crate::policy_file::Compiled {
        let text = std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/policy.toml")).unwrap();
        crate::policy_file::parse(&text).unwrap().compile().unwrap()
    }

    #[test]
    fn evaluate_takes_policy() {
        let p = compiled();
        assert_eq!(evaluate(&p, "bash", "sudo ls", "", "", "").decision, "deny");
        assert_eq!(evaluate(&p, "bash", "ness policy apply x", "", "", "").decision, "deny");
        assert_eq!(evaluate(&p, "write", "", "/Users/x/.config/ness/policy.toml", "", "").decision, "deny");
        assert_eq!(evaluate(&p, "bash", "ls", "", "", "").decision, "allow");
    }

    #[test]
    fn regex_runtime_error_denies() {
        let mut p = compiled();
        // fancy-regex backtrack limit of 1 makes any match attempt error out.
        p.dangerous = vec![fancy_regex::RegexBuilder::new(r"(a+)+b").backtrack_limit(1).build().unwrap()];
        let d = evaluate(&p, "bash", "aaaaaaaaaaaaaaaaaaaaaaaaaaaac", "", "", "");
        assert_eq!(d.decision, "deny");
        assert!(d.reason.starts_with("policy pattern error"), "{}", d.reason);
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml policy::tests`
Expected: compile error (`evaluate` takes 5 args, `is_interactive_launch` etc.).

- [ ] **Step 3: Rewrite the top of `policy.rs`**

Replace lines 1-184 (module doc through `COMMIT_COMMAND`) with:

```rust
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
        Self { decision: "allow".to_string(), reason: String::new() }
    }

    pub fn warn(reason: impl Into<String>) -> Self {
        Self { decision: "warn".to_string(), reason: reason.into() }
    }

    pub fn deny(reason: impl Into<String>) -> Self {
        Self { decision: "deny".to_string(), reason: reason.into() }
    }

    pub fn allowed(&self) -> bool {
        self.decision == "allow" || self.decision == "warn"
    }
}

/// A pattern that errors at match time is reported, and every caller turns
/// the error into a deny.
fn matches(re: &Regex, text: &str) -> Result<bool, String> {
    re.is_match(text).map_err(|e| format!("policy pattern error: {e}"))
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
```

- [ ] **Step 4: Rewrite the evaluation functions**

Replace the old `evaluate` through `writes_to` (old lines 186-301) with:

```rust
pub fn evaluate(p: &Compiled, tool: &str, command: &str, path: &str, content: &str, cwd: &str) -> GuardDecision {
    let normalized_tool = tool.to_lowercase();
    let result = match normalized_tool.trim() {
        "bash" | "shell" | "exec" => evaluate_command(p, command, cwd),
        "write" | "edit" | "file_write" | "file_edit" => evaluate_write(p, path, content),
        _ => Ok(GuardDecision::allow()),
    };
    result.unwrap_or_else(GuardDecision::deny)
}

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
        return Ok(GuardDecision::deny(format!("protected file blocked: {target}")));
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
    let warning = main_branch_commit_warning(p, command, cwd)?;
    if !warning.is_empty() {
        return Ok(GuardDecision::warn(warning));
    }
    Ok(GuardDecision::allow())
}

pub fn evaluate_write(p: &Compiled, path: &str, content: &str) -> Result<GuardDecision, String> {
    if !path.is_empty() {
        let normalized = crate::paths::normalize_str(path);
        if matches(&p.protected_paths, &normalized)? {
            return Ok(GuardDecision::deny(format!("protected file blocked: {path}")));
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

pub fn candidate_write_targets(p: &Compiled, command: &str) -> Result<Vec<String>, String> {
    let mut targets: Vec<String> = Vec::new();
    for pattern in [&p.redirect, &p.mutating_argv, &p.sed_inplace, &p.dd] {
        for caps in pattern.captures_iter(command) {
            let caps = caps.map_err(|e| format!("policy pattern error: {e}"))?;
            let Some(span) = caps.name("span") else { continue };
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

pub fn writes_to(p: &Compiled, command: &str, pattern: &Regex) -> Result<String, String> {
    for target in candidate_write_targets(p, command)? {
        if matches(pattern, &crate::paths::normalize_str(&target))? {
            return Ok(target);
        }
    }
    Ok(String::new())
}
```

Change `main_branch_commit_warning`'s signature and first lines to:

```rust
pub fn main_branch_commit_warning(p: &Compiled, command: &str, cwd: &str) -> Result<String, String> {
    if !matches(&p.commit_command, command)? {
        return Ok(String::new());
    }
```

and wrap its three remaining `return` values and the final expression in `Ok(...)`. `run_git` is unchanged.

- [ ] **Step 5: Fix callers so the crate compiles**

`crates/ness/src/guard_eval.rs`: change the signature and first line to

```rust
pub fn evaluate_with_manifest(
    p: &Compiled,
    tool: &str,
    command: &str,
    path: &str,
    content: &str,
    cwd: &str,
    manifest_path: &Path,
) -> GuardDecision {
    let decision = policy::evaluate(p, tool, command, path, content, cwd);
```

with `use crate::policy_file::Compiled;` added. In `crates/ness/src/hook.rs` and `crates/ness/src/main.rs`, every `evaluate_with_manifest(` call gains a leading `p,` argument, every hook entry point (`run_claude`, `run_codex`, `run_grok`, `run_crush`, `run_antigravity`, `run_cursor`, `evaluate_apply_patch`, `run_guard`, `run_hook`) gains a first parameter `p: &Compiled`, and `hook.rs:144` becomes:

```rust
    if harness == "codex" {
        match crate::policy::is_interactive_launch(p, &command) {
            Ok(true) => { /* existing deny branch body */ }
            Ok(false) => {}
            Err(reason) => { /* same deny branch body, with `reason` as the reason text */ }
        }
    }
```

For this task only, `main.rs` obtains `p` by loading the fixture-free real file directly so the crate builds; Task 4 replaces this with `active::load()`:

```rust
let text = std::fs::read_to_string(paths::home_dir().join(".config/ness/policy.toml")).expect("policy");
let p = policy_file::parse(&text).and_then(|p| p.compile()).expect("policy");
```

- [ ] **Step 6: Run unit tests**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml --lib`
Expected: all `policy_file` and `policy::tests` tests pass (`6 passed`). The integration tests in `tests/corpus.rs` are expected to fail until Task 5.

- [ ] **Step 7: Commit**

```bash
git -C $W add crates/ness/src
git -C $W commit -m "refactor(ness): evaluate against a loaded policy, deny on regex error" -- crates/ness/src
```

---

### Task 4: Active policy, `applied.json`, and `REQUIRED_PROTECTION`

**Files:**
- Create: `crates/ness/src/active.rs`
- Modify: `crates/ness/src/main.rs` (replace the Task 3 stopgap)
- Modify: `crates/ness/src/paths.rs` (two path helpers)

**Human-applied.**

- [ ] **Step 1: Add path helpers**

Append to `crates/ness/src/paths.rs`:

```rust
/// `~/.config/ness/policy.toml`: the one place the guard reads policy from.
pub fn policy_path() -> PathBuf {
    home_dir().join(".config").join("ness").join("policy.toml")
}

/// `~/.config/ness/cases/`: guard cases, agent-writable.
pub fn cases_dir() -> PathBuf {
    home_dir().join(".config").join("ness").join("cases")
}

/// `~/.local/state/ness/applied.json`: hashes recorded by the last human apply.
pub fn applied_path() -> PathBuf {
    home_dir().join(".local").join("state").join("ness").join("applied.json")
}
```

- [ ] **Step 2: Write the failing tests**

`crates/ness/src/active.rs`, tests module (module body in Step 4):

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};

    static N: AtomicUsize = AtomicUsize::new(0);

    fn temp_home() -> std::path::PathBuf {
        let d = std::env::temp_dir().join(format!("ness-active-{}-{}", std::process::id(), N.fetch_add(1, Ordering::SeqCst)));
        std::fs::create_dir_all(d.join(".config/ness/cases")).unwrap();
        std::fs::create_dir_all(d.join(".local/state/ness")).unwrap();
        d
    }

    fn fixture() -> String {
        std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/policy.toml")).unwrap()
    }

    #[test]
    fn missing_policy_is_an_error_naming_the_path() {
        let home = temp_home();
        let err = load_from(&home.join(".config/ness/policy.toml"), &home.join(".local/state/ness/applied.json")).unwrap_err();
        assert!(err.contains("policy.toml") && err.contains("ness policy check"), "{err}");
    }

    #[test]
    fn unapplied_policy_is_an_error() {
        let home = temp_home();
        std::fs::write(home.join(".config/ness/policy.toml"), fixture()).unwrap();
        let err = load_from(&home.join(".config/ness/policy.toml"), &home.join(".local/state/ness/applied.json")).unwrap_err();
        assert!(err.contains("not applied"), "{err}");
    }

    #[test]
    fn hash_mismatch_is_an_error() {
        let home = temp_home();
        let policy = home.join(".config/ness/policy.toml");
        std::fs::write(&policy, fixture()).unwrap();
        let applied = Applied { policy_sha256: "0".repeat(64), applied_at: "x".into(), cases: Default::default() };
        std::fs::write(home.join(".local/state/ness/applied.json"), serde_json::to_string(&applied).unwrap()).unwrap();
        let err = load_from(&policy, &home.join(".local/state/ness/applied.json")).unwrap_err();
        assert!(err.contains("differs from the last apply"), "{err}");
    }

    #[test]
    fn applied_policy_loads() {
        let home = temp_home();
        let policy = home.join(".config/ness/policy.toml");
        std::fs::write(&policy, fixture()).unwrap();
        let applied = Applied { policy_sha256: sha256_file(&policy).unwrap(), applied_at: "x".into(), cases: case_digests(&home.join(".config/ness/cases")).unwrap() };
        std::fs::write(home.join(".local/state/ness/applied.json"), serde_json::to_string(&applied).unwrap()).unwrap();
        let c = load_from(&policy, &home.join(".local/state/ness/applied.json")).unwrap();
        assert_eq!(c.dangerous.len(), 2);
    }

    #[test]
    fn required_protection_rejects_unprotected_policy_path() {
        let text = fixture().replace(r"'/\.config/ness/policy\.toml(?![\w.-])', ", "");
        let c = crate::policy_file::parse(&text).unwrap().compile().unwrap();
        let err = check_required_protection(&c).unwrap_err();
        assert!(err.contains("policy.toml"), "{err}");
    }

    #[test]
    fn required_protection_rejects_missing_apply_deny() {
        let text = fixture().replace(r", '(?i)\bness\s+policy\s+apply\b'", "");
        let c = crate::policy_file::parse(&text).unwrap().compile().unwrap();
        let err = check_required_protection(&c).unwrap_err();
        assert!(err.contains("ness policy apply"), "{err}");
    }
}
```

- [ ] **Step 3: Run to verify they fail**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml active`
Expected: compile error, `load_from`, `Applied`, `sha256_file`, `case_digests`, `check_required_protection` not defined.

- [ ] **Step 4: Write the module**

Top of `crates/ness/src/active.rs`:

```rust
//! The active policy: `~/.config/ness/policy.toml` verified against
//! `~/.local/state/ness/applied.json`, the record a human wrote with
//! `ness policy apply`. Every failure here is a reason string that becomes
//! a deny on every verdict (decision 2026-10-17-ness-policy-as-data,
//! clauses 2 and 3).

use crate::policy_file::{self, Compiled};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::path::Path;

#[derive(Debug, Serialize, Deserialize)]
pub struct Applied {
    pub policy_sha256: String,
    pub applied_at: String,
    /// sha256 per case file name at apply time, so `check` can name what
    /// was added, removed, or changed. Lives inside this control-plane file
    /// on purpose: a sidecar would be forgeable.
    pub cases: BTreeMap<String, String>,
}

/// Inputs the policy must protect no matter what it says (clause 3). Paths
/// are matched the way the guard matches them: normalized and tested against
/// `[control_plane]`. The command is tested against `[commands.dangerous]`.
pub const REQUIRED_PROTECTED_PATHS: &[&str] = &[
    "~/.config/ness/policy.toml",
    "~/.local/state/ness/applied.json",
    "~/.local/bin/ness",
];
pub const REQUIRED_DENIED_COMMAND: &str = "ness policy apply";

pub fn sha256_file(path: &Path) -> Result<String, String> {
    let bytes = std::fs::read(path).map_err(|e| format!("read {}: {e}", path.display()))?;
    Ok(format!("{:x}", Sha256::digest(bytes)))
}

/// sha256 of every `*.json` case in `dir`, keyed by file name.
pub fn case_digests(dir: &Path) -> Result<BTreeMap<String, String>, String> {
    let mut out = BTreeMap::new();
    let Ok(rd) = std::fs::read_dir(dir) else { return Ok(out) };
    for entry in rd.filter_map(|e| e.ok()) {
        let name = entry.file_name().to_string_lossy().into_owned();
        if !name.ends_with(".json") {
            continue;
        }
        let bytes = std::fs::read(entry.path()).map_err(|e| format!("read {name}: {e}"))?;
        out.insert(name, format!("{:x}", Sha256::digest(bytes)));
    }
    Ok(out)
}

pub fn read_applied(path: &Path) -> Result<Applied, String> {
    let text = std::fs::read_to_string(path).map_err(|e| format!("read {}: {e}", path.display()))?;
    serde_json::from_str(&text).map_err(|e| format!("parse {}: {e}", path.display()))
}

pub fn check_required_protection(p: &Compiled) -> Result<(), String> {
    for path in REQUIRED_PROTECTED_PATHS {
        let normalized = crate::paths::normalize_str(path);
        match p.control_plane.is_match(&normalized) {
            Ok(true) => {}
            Ok(false) => return Err(format!("[control_plane] must cover {path}")),
            Err(e) => return Err(format!("policy pattern error: {e}")),
        }
    }
    let mut denied = false;
    for re in &p.dangerous {
        if re.is_match(REQUIRED_DENIED_COMMAND).map_err(|e| format!("policy pattern error: {e}"))? {
            denied = true;
            break;
        }
    }
    if !denied {
        return Err(format!("[commands.dangerous] must deny `{REQUIRED_DENIED_COMMAND}`"));
    }
    Ok(())
}

/// Parse, compile, and invariant-check a policy file without any applied
/// check: what `ness policy check` does to a candidate.
pub fn load_candidate(path: &Path) -> Result<Compiled, String> {
    let text = std::fs::read_to_string(path).map_err(|e| format!("read {}: {e}", path.display()))?;
    let compiled = policy_file::parse(&text)?.compile()?;
    check_required_protection(&compiled)?;
    Ok(compiled)
}

pub fn load_from(policy: &Path, applied: &Path) -> Result<Compiled, String> {
    let remedy = "run `ness policy check` and have a human run `ness policy apply`";
    if !policy.is_file() {
        return Err(format!("policy missing at {}; {remedy}", policy.display()));
    }
    let actual = sha256_file(policy)?;
    let record = read_applied(applied).map_err(|_| format!("policy at {} is not applied (no {}); {remedy}", policy.display(), applied.display()))?;
    if record.policy_sha256 != actual {
        return Err(format!("policy at {} differs from the last apply; {remedy}", policy.display()));
    }
    load_candidate(policy).map_err(|e| format!("{e}; {remedy}"))
}

/// The guard's entry point: the active policy or the reason every verdict
/// is a deny.
pub fn load() -> Result<Compiled, String> {
    load_from(&crate::paths::policy_path(), &crate::paths::applied_path())
}
```

Add `mod active;` to `main.rs`. Replace the Task 3 stopgap in `run_guard` and `run_hook` with:

```rust
let policy = active::load();
```

and change `evaluate_with_manifest` to take `p: Result<&Compiled, &str>` (callers pass `policy.as_ref().map_err(String::as_str)`), returning `GuardDecision::deny(reason)` immediately on `Err(reason)`. `hook.rs`'s `is_interactive_launch` call site likewise does nothing when the policy is `Err` (the deny already came from `evaluate_with_manifest`). This way every harness-native output shape is produced by the existing hook code; only the decision changes. Add `use std::collections::BTreeMap;` to `active.rs`.

- [ ] **Step 5: Run the tests**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml --lib`
Expected: `12 passed` (4 policy_file + 1 real_policy + 2 policy + 6 active... adjust to the actual count; all green).

- [ ] **Step 6: Commit**

```bash
git -C $W add crates/ness/src
git -C $W commit -m "feat(ness): load the active policy verified against applied.json" -- crates/ness/src
```

---

### Task 5: Move the corpus to `.config/ness/cases/` and make the integration tests use a fake `$HOME`

**Files:**
- Move: `crates/ness/tests/corpus/*.json` → `.config/ness/cases/` (127 files, `git mv`)
- Create: `.config/ness/cases/905-deny-controlplane-policy-toml.json`, `906-deny-controlplane-applied-json.json`, `907-deny-bash-ness-policy-apply.json`, `908-allow-bash-ness-policy-check.json`, `909-deny-controlplane-ness-binary.json`
- Modify: `crates/ness/tests/corpus.rs:43-61` (`load`), `:83-93` (`run_guard`), `:125-136` (`fake_home`)

The `git mv` and the five new case files are worker-editable (cases are not control plane; `crates/ness/tests/corpus/` is, so the **move itself is human-applied**: the worker runs the `git mv` command only after the human confirms, or the human runs it). `corpus.rs` is **human-applied**.

- [ ] **Step 1: Move the cases**

```bash
mkdir -p $W/.config/ness/cases
git -C $W mv crates/ness/tests/corpus/*.json .config/ness/cases/
ls $W/.config/ness/cases | wc -l
```

Expected: `127`.

- [ ] **Step 2: Add the five new cases**

`.config/ness/cases/905-deny-controlplane-policy-toml.json`:

```json
{
  "command": null,
  "content": "[control_plane]\npatterns = []\n",
  "cwd": null,
  "expected": {
    "decision": "deny",
    "reason": "control-plane file is human-only: ~/.config/ness/policy.toml. It decides what the guard permits, so edit it directly rather than through an agent."
  },
  "harness": "claude",
  "path": "~/.config/ness/policy.toml",
  "tool": "write"
}
```

`.config/ness/cases/906-deny-controlplane-applied-json.json`:

```json
{
  "command": "rm ~/.local/state/ness/applied.json",
  "content": null,
  "cwd": null,
  "expected": {
    "decision": "deny",
    "reason": "control-plane file is human-only: ~/.local/state/ness/applied.json. It decides what the guard permits, so edit it directly rather than through an agent."
  },
  "harness": "claude",
  "path": null,
  "tool": "bash"
}
```

`.config/ness/cases/907-deny-bash-ness-policy-apply.json`:

```json
{
  "command": "ness policy apply /tmp/candidate/policy.toml",
  "content": null,
  "cwd": null,
  "expected": {
    "decision": "deny",
    "reason": "Dangerous command pattern detected"
  },
  "harness": "codex",
  "path": null,
  "tool": "bash"
}
```

`.config/ness/cases/908-allow-bash-ness-policy-check.json`:

```json
{
  "command": "ness policy check /tmp/candidate/policy.toml",
  "content": null,
  "cwd": null,
  "expected": {
    "decision": "allow",
    "reason": ""
  },
  "harness": "codex",
  "path": null,
  "tool": "bash"
}
```

`.config/ness/cases/909-deny-controlplane-ness-binary.json`:

```json
{
  "command": "cp target/release/ness ~/.local/bin/ness",
  "content": null,
  "cwd": null,
  "expected": {
    "decision": "deny",
    "reason": "control-plane file is human-only: ~/.local/bin/ness. It decides what the guard permits, so edit it directly rather than through an agent."
  },
  "harness": "claude",
  "path": null,
  "tool": "bash"
}
```

- [ ] **Step 3: Update `corpus.rs` to load from the new directory and run under a fake `$HOME`**

Replace `load`'s first line with:

```rust
fn load(dir: &str) -> Vec<(String, Value)> {
    let path = match dir {
        "corpus" => repo_root().join(".config").join("ness").join("cases"),
        other => Path::new(env!("CARGO_MANIFEST_DIR")).join("tests").join(other),
    };
```

Replace `fake_home` with:

```rust
/// A `$HOME` with the repo's policy installed and applied, so a binary run
/// under it loads the same policy the corpus was written against. `ness`
/// is linked into `.local/bin` when given, for the shim tests.
fn fake_home(ness: Option<&Path>) -> PathBuf {
    let home = temp_dir();
    let cfg = home.join(".config").join("ness");
    std::fs::create_dir_all(cfg.join("cases")).unwrap();
    std::fs::copy(repo_root().join(".config/ness/policy.toml"), cfg.join("policy.toml")).unwrap();
    for (name, case) in load("corpus") {
        std::fs::write(cfg.join("cases").join(&name), serde_json::to_string_pretty(&case).unwrap()).unwrap();
    }
    let state = home.join(".local").join("state").join("ness");
    std::fs::create_dir_all(&state).unwrap();
    let out = Command::new(built_ness())
        .args(["policy", "apply", "--for-tests", cfg.join("policy.toml").to_str().unwrap()])
        .env("HOME", &home)
        .output()
        .expect("spawn ness policy apply --for-tests");
    assert!(out.status.success(), "apply --for-tests: {}", String::from_utf8_lossy(&out.stderr));
    if let Some(ness) = ness {
        let bin_dir = home.join(".local").join("bin");
        std::fs::create_dir_all(&bin_dir).unwrap();
        std::os::unix::fs::symlink(ness, bin_dir.join("ness")).unwrap();
    }
    home
}
```

`--for-tests` is a hidden flag Task 6 adds to `apply`: it skips the TTY and confirmation checks **only when the target `$HOME` is under the system temp dir**, so a real apply can never be scripted with it. Change `run_guard` to set `HOME`:

```rust
fn run_guard(binary: &Path, home: &Path, case: &Value) -> (i32, Value) {
    let output = Command::new(binary)
        .arg("guard")
        .args(guard_args(case))
        .current_dir(repo_root())
        .env("HOME", home)
        .output()
        .unwrap_or_else(|e| panic!("spawn {}: {e}", binary.display()));
```

and in `guard_mismatches` create `let home = fake_home(None);` once and pass it. `installed_copy_matches_corpus` keeps using the real `$HOME` (it is the proof that the installed binary and the applied real policy agree): pass `&paths_home()` where `fn paths_home() -> PathBuf { PathBuf::from(std::env::var("HOME").unwrap()) }`.

- [ ] **Step 4: Run the integration tests**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml --test corpus`
Expected: fails until Task 6 provides `policy apply --for-tests`. Proceed to Task 6, then return here.

- [ ] **Step 5 (after Task 6): Run again**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml --test corpus`
Expected: `guard_corpus_matches_expected`, `hook_corpus_matches_expected`, `reshaped_corpus_matches_shims`, `shims_fail_closed_without_ness`, `main_branch_commit_warning_forwards_cwd` pass; `installed_copy_matches_corpus` skipped. 132 cases run. (`fake_home` relies on `--for-tests`, which only works when `$HOME` is under `std::env::temp_dir()`; `corpus.rs`'s `temp_dir()` helper builds on `std::env::temp_dir()`, so this holds.)

- [ ] **Step 6: Commit (one commit for the move plus the harness changes)**

```bash
git -C $W add .config/ness/cases crates/ness/tests/corpus.rs
git -C $W commit -m "test(ness): move guard cases to .config/ness/cases, run under a fake HOME" -- .config/ness/cases crates/ness/tests/corpus crates/ness/tests/corpus.rs
```

---

### Task 6: `ness policy check | apply | active`

**Files:**
- Create: `crates/ness/src/policy_cmd.rs`
- Modify: `crates/ness/src/main.rs:129-155` (dispatch and usage)

**Human-applied.**

- [ ] **Step 1: Write the failing integration test**

Append to `crates/ness/tests/corpus.rs`:

```rust
#[test]
fn policy_check_reports_verdict_diff_and_case_delta() {
    let home = fake_home(None);
    let proposals = home.join(".local/state/ness/proposals/t");
    std::fs::create_dir_all(&proposals).unwrap();
    // Candidate: drop the credential-disclosure rule; cases 145/146 flip to allow.
    let text = std::fs::read_to_string(home.join(".config/ness/policy.toml")).unwrap();
    let candidate = text.replace(
        r"patterns = ['(?i)\bgh\s+auth\s+(?:token\b|status\b[^;&|\n]*\s(?:--show-token|-t)\b)']",
        "patterns = ['(?i)\\bgh\\s+auth\\s+never-matches-anything\\b']",
    );
    assert_ne!(candidate, text);
    std::fs::write(proposals.join("policy.toml"), candidate).unwrap();
    // Delete a case so the delta is non-empty.
    std::fs::remove_file(home.join(".config/ness/cases/147-allow-gh-auth-status.json")).unwrap();

    let out = Command::new(built_ness())
        .args(["policy", "check", proposals.join("policy.toml").to_str().unwrap()])
        .env("HOME", &home)
        .current_dir(repo_root())
        .output()
        .unwrap();
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert_eq!(out.status.code(), Some(1), "{stdout}");
    assert!(stdout.contains("145-deny-gh-auth-token.json: expected deny"), "{stdout}");
    assert!(stdout.contains("verdict diff: 2 case(s)"), "{stdout}");
    assert!(stdout.contains("removed: 147-allow-gh-auth-status.json"), "{stdout}");
}

#[test]
fn policy_apply_refuses_without_tty() {
    let home = fake_home(None);
    let out = Command::new(built_ness())
        .args(["policy", "apply", home.join(".config/ness/policy.toml").to_str().unwrap()])
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
    let out = Command::new(built_ness()).args(["policy"]).env("HOME", &home).output().unwrap();
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(out.status.success(), "{stdout}");
    assert!(stdout.contains("verified: yes") && stdout.contains("commands.dangerous: 10"), "{stdout}");
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml --test corpus policy_`
Expected: 3 failures, `ness: unknown subcommand 'policy'`.

- [ ] **Step 3: Write `policy_cmd.rs`**

```rust
//! `ness policy check|apply|active` (decision 2026-10-17-ness-policy-as-data,
//! clauses 5-8). `check` is agent-runnable; `apply` is the one human action.

use crate::active::{self, Applied};
use crate::guard_eval::evaluate_with_manifest;
use crate::policy_file::Compiled;
use crate::paths;
use serde_json::Value;
use std::collections::BTreeMap;
use std::io::{BufRead, IsTerminal, Write};
use std::path::{Path, PathBuf};

struct Case {
    name: String,
    value: Value,
}

fn load_cases(dir: &Path) -> Result<Vec<Case>, String> {
    let mut cases = Vec::new();
    let Ok(rd) = std::fs::read_dir(dir) else { return Ok(cases) };
    for entry in rd.filter_map(|e| e.ok()) {
        let name = entry.file_name().to_string_lossy().into_owned();
        if !name.ends_with(".json") {
            continue;
        }
        let text = std::fs::read_to_string(entry.path()).map_err(|e| format!("read {name}: {e}"))?;
        let value: Value = serde_json::from_str(&text).map_err(|e| format!("parse {name}: {e}"))?;
        cases.push(Case { name, value });
    }
    cases.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(cases)
}

fn str_field<'a>(v: &'a Value, key: &str) -> &'a str {
    v.get(key).and_then(Value::as_str).unwrap_or("")
}

/// Same evaluation `ness guard` performs, in-process, against a given policy.
fn verdict(p: &Compiled, case: &Value) -> (String, String) {
    let cwd = {
        let c = str_field(case, "cwd");
        if c.is_empty() { paths::find_root().to_string_lossy().into_owned() } else { c.to_string() }
    };
    let manifest = paths::find_root().join(".agents/harness/generated-paths.json");
    let d = evaluate_with_manifest(
        Ok(p),
        str_field(case, "tool"),
        str_field(case, "command"),
        str_field(case, "path"),
        str_field(case, "content"),
        &cwd,
        &manifest,
    );
    (d.decision, d.reason)
}

struct CheckReport {
    errors: Vec<String>,
    failures: Vec<String>,
    diff: Vec<String>,
    added: Vec<String>,
    removed: Vec<String>,
    changed: Vec<String>,
    active_err: Option<String>,
}

impl CheckReport {
    fn exit_code(&self) -> i32 {
        if self.errors.is_empty() && self.failures.is_empty() && self.removed.is_empty() && self.changed.is_empty() { 0 } else { 1 }
    }
    fn only_case_changes(&self) -> bool {
        self.errors.is_empty() && self.failures.is_empty() && !(self.removed.is_empty() && self.changed.is_empty())
    }
}

fn applied_case_digests() -> BTreeMap<String, String> {
    active::read_applied(&paths::applied_path()).map(|a| a.cases).unwrap_or_default()
}

fn run_check(candidate: &Path, out: &mut dyn Write) -> Result<CheckReport, String> {
    let mut r = CheckReport { errors: vec![], failures: vec![], diff: vec![], added: vec![], removed: vec![], changed: vec![], active_err: None };
    let compiled = match active::load_candidate(candidate) {
        Ok(c) => c,
        Err(e) => {
            r.errors.push(e);
            writeln!(out, "schema: {}", r.errors[0]).ok();
            return Ok(r);
        }
    };
    writeln!(out, "schema: ok").ok();
    writeln!(out, "invariants: ok").ok();

    let cases = load_cases(&paths::cases_dir())?;
    let active = active::load();
    for c in &cases {
        let (dec, reason) = verdict(&compiled, &c.value);
        let exp_dec = str_field(&c.value["expected"], "decision");
        let exp_reason = str_field(&c.value["expected"], "reason");
        if dec != exp_dec || reason != exp_reason {
            r.failures.push(format!("{}: expected {exp_dec} {exp_reason:?}; got {dec} {reason:?}", c.name));
        }
        if let Ok(a) = &active {
            let (adec, areason) = verdict(a, &c.value);
            if adec != dec || areason != reason {
                r.diff.push(format!("{}: {adec} {areason:?} -> {dec} {reason:?}", c.name));
            }
        }
    }
    if let Err(e) = &active {
        r.active_err = Some(e.clone());
    }
    writeln!(out, "cases: {} run, {} failed", cases.len(), r.failures.len()).ok();
    for f in &r.failures {
        writeln!(out, "  {f}").ok();
    }
    if let Some(e) = &r.active_err {
        writeln!(out, "verdict diff: skipped (active policy not loadable: {e})").ok();
    } else {
        writeln!(out, "verdict diff: {} case(s)", r.diff.len()).ok();
        for d in &r.diff {
            writeln!(out, "  {d}").ok();
        }
    }

    let now = active::case_digests(&paths::cases_dir())?;
    let then = applied_case_digests();
    for (name, h) in &now {
        match then.get(name) {
            None => r.added.push(name.clone()),
            Some(old) if old != h => r.changed.push(name.clone()),
            _ => {}
        }
    }
    for name in then.keys() {
        if !now.contains_key(name) {
            r.removed.push(name.clone());
        }
    }
    writeln!(out, "case delta since last apply: {} added, {} removed, {} changed", r.added.len(), r.removed.len(), r.changed.len()).ok();
    for n in &r.added { writeln!(out, "  added: {n}").ok(); }
    for n in &r.removed { writeln!(out, "  removed: {n}").ok(); }
    for n in &r.changed { writeln!(out, "  changed: {n}").ok(); }
    Ok(r)
}

pub fn check(candidate: &Path) -> i32 {
    let mut stdout = std::io::stdout();
    match run_check(candidate, &mut stdout) {
        Ok(r) => r.exit_code(),
        Err(e) => {
            eprintln!("ness policy check: {e}");
            2
        }
    }
}

fn write_applied(policy: &Path) -> Result<(), String> {
    let applied_path = paths::applied_path();
    std::fs::create_dir_all(applied_path.parent().unwrap()).map_err(|e| e.to_string())?;
    let record = Applied {
        policy_sha256: active::sha256_file(policy)?,
        applied_at: chrono_free_now(),
        cases: active::case_digests(&paths::cases_dir())?,
    };
    std::fs::write(&applied_path, serde_json::to_string_pretty(&record).unwrap()).map_err(|e| e.to_string())?;
    Ok(())
}

/// RFC 3339 UTC without pulling in a date crate.
fn chrono_free_now() -> String {
    let secs = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
    let days = secs / 86400;
    let (h, m, s) = ((secs % 86400) / 3600, (secs % 3600) / 60, secs % 60);
    // civil-from-days (Howard Hinnant), valid for the Unix era.
    let z = days as i64 + 719468;
    let era = z.div_euclid(146097);
    let doe = z.rem_euclid(146097);
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let mo = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if mo <= 2 { y + 1 } else { y };
    format!("{y:04}-{mo:02}-{d:02}T{h:02}:{m:02}:{s:02}Z")
}

fn atomic_replace(candidate: &Path, target: &Path) -> Result<(), String> {
    if candidate.canonicalize().ok() == target.canonicalize().ok() {
        return Ok(()); // bootstrap: applying the tracked file onto itself
    }
    let tmp = target.with_extension("toml.new");
    std::fs::copy(candidate, &tmp).map_err(|e| format!("copy to {}: {e}", tmp.display()))?;
    std::fs::rename(&tmp, target).map_err(|e| format!("rename to {}: {e}", target.display()))
}

pub fn apply(candidate: &Path, accept_case_changes: bool, for_tests: bool) -> i32 {
    let home = paths::home_dir();
    let test_mode = for_tests && home.starts_with(std::env::temp_dir());
    if for_tests && !test_mode {
        eprintln!("ness policy apply: --for-tests is only honored when HOME is under the temp dir");
        return 2;
    }
    if !test_mode && !std::io::stdin().is_terminal() {
        eprintln!("ness policy apply: requires a terminal on stdin; a human runs this");
        return 2;
    }
    let mut buf: Vec<u8> = Vec::new();
    let report = match run_check(candidate, &mut buf) {
        Ok(r) => r,
        Err(e) => {
            eprintln!("ness policy apply: {e}");
            return 2;
        }
    };
    print!("{}", String::from_utf8_lossy(&buf));
    if report.exit_code() != 0 {
        if !(report.only_case_changes() && (accept_case_changes || test_mode)) {
            eprintln!("ness policy apply: refusing; fix the failures above{}", if report.only_case_changes() { " or pass --accept-case-changes" } else { "" });
            return 1;
        }
        if !test_mode {
            print!("Accept the removed/changed cases listed above? Type yes: ");
            std::io::stdout().flush().ok();
            let mut line = String::new();
            std::io::stdin().lock().read_line(&mut line).ok();
            if line.trim() != "yes" {
                eprintln!("ness policy apply: not confirmed");
                return 1;
            }
        }
    }
    let target = paths::policy_path();
    if let Err(e) = std::fs::create_dir_all(target.parent().unwrap()) {
        eprintln!("ness policy apply: {e}");
        return 2;
    }
    if let Err(e) = atomic_replace(candidate, &target).and_then(|_| write_applied(&target)) {
        eprintln!("ness policy apply: {e}");
        return 2;
    }
    println!("applied {} -> {}", candidate.display(), target.display());
    0
}

pub fn active_cmd() -> i32 {
    let policy = paths::policy_path();
    let applied = paths::applied_path();
    println!("policy: {}", policy.display());
    match active::sha256_file(&policy) {
        Ok(h) => println!("sha256: {h}"),
        Err(e) => println!("sha256: unavailable ({e})"),
    }
    match active::read_applied(&applied) {
        Ok(a) => println!("applied_at: {}", a.applied_at),
        Err(_) => println!("applied_at: never ({} missing)", applied.display()),
    }
    match active::load() {
        Ok(c) => {
            println!("verified: yes");
            for (name, n) in &c.counts {
                println!("{name}: {n}");
            }
            0
        }
        Err(e) => {
            println!("verified: no ({e})");
            1
        }
    }
}

pub fn run(args: &[String]) -> i32 {
    match args.first().map(String::as_str) {
        None | Some("active") => active_cmd(),
        Some("check") => match args.get(1) {
            Some(p) => check(&PathBuf::from(p)),
            None => { eprintln!("usage: ness policy check <candidate.toml>"); 2 }
        },
        Some("apply") => {
            let accept = args.iter().any(|a| a == "--accept-case-changes");
            let for_tests = args.iter().any(|a| a == "--for-tests");
            match args.iter().skip(1).find(|a| !a.starts_with("--")) {
                Some(p) => apply(&PathBuf::from(p), accept, for_tests),
                None => { eprintln!("usage: ness policy apply [--accept-case-changes] <candidate.toml>"); 2 }
            }
        }
        Some(other) => { eprintln!("ness policy: unknown action '{other}' (expected check, apply, or active)"); 2 }
    }
}
```

- [ ] **Step 4: Wire the subcommand in `main.rs`**

In `main()`, before `parse_flags` (which rejects positional args), add:

```rust
    if subcommand == "policy" {
        std::process::exit(policy_cmd::run(&args[1..]));
    }
```

Add `mod policy_cmd;` and extend the usage string to `usage: ness <guard|hook|policy> ...`.

- [ ] **Step 5: Run the full crate tests**

Run: `cargo test --manifest-path $W/crates/ness/Cargo.toml`
Expected: all unit tests and all `corpus` tests pass, including the three new `policy_*` tests and Task 5's corpus run. `cargo clippy --manifest-path $W/crates/ness/Cargo.toml --all-targets` reports no warnings.

- [ ] **Step 6: Commit**

```bash
git -C $W add crates/ness/src crates/ness/tests/corpus.rs
git -C $W commit -m "feat(ness): add policy check, apply, and active subcommands" -- crates/ness/src crates/ness/tests/corpus.rs
```

---

### Task 7: Equivalence against the baseline binary

**Files:** none modified.

- [ ] **Step 1: Every migrated case gives the baseline binary's verdict**

`cargo test --test corpus guard_corpus_matches_expected` (Task 6 Step 5) already proves the new binary matches the case expectations. Prove the expectations are the baseline's verdicts too:

```bash
cd $W && python3 - <<'PY'
import json, subprocess, pathlib
bad = []
for f in sorted(pathlib.Path(".config/ness/cases").glob("*.json")):
    if f.name.startswith(("905","906","907","908","909")): continue  # new rules, absent from baseline
    c = json.loads(f.read_text())
    args = ["/tmp/ness-baseline/ness","guard","--harness",c["harness"],"--tool",c["tool"]]
    for k in ("command","path","content","cwd"):
        if c.get(k) is not None: args += ["--"+k, c[k]]
    got = json.loads(subprocess.run(args, capture_output=True, text=True).stdout)
    if (got["decision"], got["reason"]) != (c["expected"]["decision"], c["expected"]["reason"]):
        bad.append(f.name)
print("baseline mismatches:", bad)
PY
```

Expected: `baseline mismatches: []`.
No commit.

---

### Task 8: `harness_policy.py` reads `[approval]`

**Files:**
- Modify: `scripts/harness_policy.py:36-185` (delete the tuples), `:220-264` (`bash_rules`)
- Create: `tests/test_harness_policy.py`

`scripts/harness_policy.py` is **human-applied**; the test file is worker-editable.

- [ ] **Step 1: Write the failing test**

`tests/test_harness_policy.py`:

```python
#!/usr/bin/env python3
"""bash_rules() renders the [approval] tables of .config/ness/policy.toml."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import harness_policy  # noqa: E402

BASELINE = Path("/tmp/ness-baseline/bash_rules.json")


class BashRulesTests(unittest.TestCase):
    def test_reads_approval_from_policy_toml(self) -> None:
        approval = harness_policy.load_approval()
        self.assertIn("rm", approval["prompt_prefix"])
        self.assertIn("sudo", approval["deny_prefix"])
        self.assertEqual(approval["modes"]["omp_approval_mode"], "write")

    def test_omp_rules_are_ordered_deny_prompt_allow(self) -> None:
        rules = harness_policy.bash_rules("omp")
        approvals = [r["approval"] for r in rules]
        self.assertEqual(approvals[:4], ["deny", "deny", "prompt", "prompt"])
        self.assertTrue(all(a == "allow" for a in approvals[4:]))

    @unittest.skipUnless(BASELINE.exists(), "baseline snapshot from Task 0 not present")
    def test_matches_pre_change_snapshot(self) -> None:
        before = json.loads(BASELINE.read_text())
        for style in ("claude-deny", "antigravity", "opencode", "omp"):
            self.assertEqual(harness_policy.bash_rules(style), before[style], style)
        self.assertEqual(harness_policy.bash_rules("claude"), before["claude"]["rules"])
        self.assertEqual(harness_policy.OMP_APPROVAL_MODE, before["modes"]["omp_approval_mode"])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run to verify it fails**

Run: `python3 $W/tests/test_harness_policy.py`
Expected: `AttributeError: module 'harness_policy' has no attribute 'load_approval'`.

- [ ] **Step 3: Rewrite the data section of `harness_policy.py`**

Delete `BASH_ALLOW_PREFIX`, `BASH_ALLOW_EXACT`, `BASH_ASK_PREFIX`, `BASH_DENY_PREFIX`, `WEBFETCH_ALLOW_DOMAINS`, `CLAUDE_TOOL_ALLOW`, `CLAUDE_DEFAULT_MODE`, `OMP_APPROVAL_MODE`, `OPENCODE_EDIT`, `OPENCODE_EXTERNAL_DIRECTORY`, `OPENCODE_WEBFETCH` (lines 36-178 region; keep `MCP_SERVERS`, `OMP_MCP_SCHEMA`, and everything else). In their place:

```python
import tomllib
from functools import cache
from pathlib import Path

# The approval baseline lives with the rest of the safety policy
# (decision 2026-10-17-ness-policy-as-data). Read from the repo checkout so a
# worktree renders its own branch's policy, not $HOME's.
POLICY_PATH = Path(__file__).resolve().parent.parent / ".config" / "ness" / "policy.toml"


@cache
def load_approval() -> dict[str, Any]:
    with POLICY_PATH.open("rb") as fh:
        return tomllib.load(fh)["approval"]


def _modes() -> dict[str, str]:
    return load_approval()["modes"]


# Kept as module attributes for harness-apply.py and any other importer.
CLAUDE_DEFAULT_MODE = _modes()["claude_default_mode"]
OMP_APPROVAL_MODE = _modes()["omp_approval_mode"]
OPENCODE_EDIT = _modes()["opencode_edit"]
OPENCODE_EXTERNAL_DIRECTORY = _modes()["opencode_external_directory"]
OPENCODE_WEBFETCH = _modes()["opencode_webfetch"]
```

and `bash_rules` becomes:

```python
def bash_rules(style: str) -> Any:
    """Render the permission baseline in one harness's native shape."""
    a = load_approval()
    allow_prefix: list[str] = a["allow_prefix"]
    allow_exact: list[str] = a["allow_exact"]
    prompt_prefix: list[str] = a["prompt_prefix"]
    deny_prefix: list[str] = a["deny_prefix"]

    if style == "claude":
        rules = [f"Bash({cmd} *)" for cmd in allow_prefix]
        rules += [f"Bash({cmd})" for cmd in allow_exact]
        rules += [f"WebFetch(domain:{domain})" for domain in a["claude"]["webfetch_domains"]]
        rules += list(a["claude"]["tools"])
        return sorted(rules)

    if style == "claude-deny":
        return [f"Bash({cmd} *)" for cmd in deny_prefix]

    if style == "antigravity":
        return sorted(f"command({cmd})" for cmd in (*allow_prefix, *allow_exact))

    if style == "opencode":
        opencode_rules: dict[str, str] = {}
        for cmd in allow_prefix:
            opencode_rules[f"{cmd}*"] = "allow"
        for cmd in allow_exact:
            opencode_rules[cmd] = "allow"
        for cmd in prompt_prefix:
            opencode_rules[f"{cmd} *"] = "ask"
        for cmd in deny_prefix:
            opencode_rules[f"{cmd} *"] = "deny"
        return opencode_rules

    if style == "omp":
        # First-match-wins: deny, then prompt, then allow. omp accepts only
        # allow|deny|prompt and silently drops any other value.
        patterns: list[dict[str, str]] = []
        for cmd in deny_prefix:
            patterns.append({"match": f"{cmd} *", "approval": "deny"})
            patterns.append({"match": cmd, "approval": "deny"})
        for cmd in prompt_prefix:
            patterns.append({"match": f"{cmd} *", "approval": "prompt"})
            patterns.append({"match": cmd, "approval": "prompt"})
        for cmd in allow_prefix:
            patterns.append({"match": f"{cmd}*", "approval": "allow"})
        for cmd in allow_exact:
            patterns.append({"match": cmd, "approval": "allow"})
        return patterns

    raise ValueError(f"unknown bash rule style: {style!r}")
```

- [ ] **Step 4: Run the tests**

Run: `python3 $W/tests/test_harness_policy.py -v`
Expected: 3 tests OK (the snapshot test must not be skipped; `/tmp/ness-baseline/bash_rules.json` exists from Task 0).

Run: `cd $W && python3 scripts/agent-harnesses.py generate --check`
Expected: exit 0, no diff.

- [ ] **Step 5: Register the test in bats**

In `tests/agent-harnesses.bats`, after the block that runs `test_harness_skills.py` (line ~33), add:

```bash
@test "harness_policy: bash_rules renders policy.toml" {
  run python3 "$HOME/tests/test_harness_policy.py"
  [ "$status" -eq 0 ]
}
```

- [ ] **Step 6: Commit**

```bash
git -C $W add scripts/harness_policy.py tests/test_harness_policy.py tests/agent-harnesses.bats
git -C $W commit -m "refactor(harness): render approval baselines from policy.toml" -- scripts/harness_policy.py tests/test_harness_policy.py tests/agent-harnesses.bats
```

---

### Task 9: Bootstrap this machine (human)

**Files:** none in the repo. Real `$HOME` state only.

The real `$HOME` is on branch `friday`; `.config/ness/` does not exist there until this branch merges. The installed binary must not be replaced before the real `$HOME` has an applied policy.

- [ ] **Step 1: Stage the policy and cases in the real `$HOME` (untracked on `friday`)**

```bash
mkdir -p ~/.config/ness
cp $W/.config/ness/policy.toml ~/.config/ness/policy.toml
cp -R $W/.config/ness/cases ~/.config/ness/cases
```

- [ ] **Step 2: Apply it with the new binary, from a terminal (human)**

```bash
$W/crates/ness/target/release/ness policy check ~/.config/ness/policy.toml
$W/crates/ness/target/release/ness policy apply ~/.config/ness/policy.toml
```

Expected: `check` prints `schema: ok`, `invariants: ok`, `cases: 132 run, 0 failed`, `verdict diff: skipped (active policy not loadable: ... not applied ...)`, delta `132 added`, exit 0 (additions are not failures). `apply` prints `applied ~/.config/ness/policy.toml -> ~/.config/ness/policy.toml`.

- [ ] **Step 3: Install the binary**

```bash
cd $W && just ness-install
```

Expected: `ness-check-installed` runs `installed_copy_matches_corpus` against `~/.local/bin/ness` with the real `$HOME` and passes.

- [ ] **Step 4: Confirm every hook still works**

From this omp session: run `ls` through the bash tool (allowed) and a write to `~/.config/ness/policy.toml` (must be denied with `control-plane file is human-only`). `ness policy` prints `verified: yes`.

- [ ] **Step 5: Latency**

```bash
python3 - <<'PY'
import subprocess, time
for name, binary in (("baseline","/tmp/ness-baseline/ness"),("new","/Users/phatblat/.local/bin/ness")):
    t=[]
    for _ in range(200):
        s=time.perf_counter()
        subprocess.run([binary,"guard","--harness","claude","--tool","bash","--command","git status"],capture_output=True)
        t.append((time.perf_counter()-s)*1000)
    t.sort(); print(f"{name} p50={t[100]:.2f}ms p95={t[190]:.2f}ms")
PY
```

Expected: `new p50` within 10 ms of `baseline p50`. If not, stop and revise the Decision (its Assumptions say so).

---

### Task 10: Docs, comments, and recipes

**Files:**
- Modify: `.agents/skills/optimize-harness/SKILL.md:38-44`
- Modify: `.agents/skills/optimize-harness/references/harness-map.md:139-142`
- Modify: `docs/tooling-dimensions.md:121`
- Modify: `.config/just/rust.just:51-70` (comments), add `ness-policy-check`
- Modify: `crates/ness/tests/corpus.rs:1-12` module doc (**human-applied**)

- [ ] **Step 1: optimize-harness control-plane note**

Replace the paragraph at `SKILL.md:38-44` with:

```markdown
## Control-plane note

`scripts/agent-harnesses.py`, `scripts/agent_plugins.py`,
`scripts/harness_policy.py`, `.agents/harness/hooks/`,
`.agents/harness/generated-paths.json`, `crates/ness/`,
`~/.config/ness/policy.toml`, and `~/.local/state/ness/applied.json` are
human-only (`[control_plane]` in `policy.toml`, floored by
`REQUIRED_PROTECTED_PATHS` in `crates/ness/src/active.rs`). Policy *content*
is data: propose a change by writing a candidate to
`~/.local/state/ness/proposals/<slug>/policy.toml`, adding cases under
`~/.config/ness/cases/`, running `ness policy check <candidate>`, and
reporting the verdict diff; the user runs `ness policy apply`. A fix in one
of the other files above is still a hand-patch for the user to apply.
```

- [ ] **Step 2: harness-map.md**

At `harness-map.md:139-142`, change `(... fixed 2026-10-16 in `scripts/harness_policy.py`)` to `(... fixed 2026-10-16; the baseline now lives in `[approval]` of `~/.config/ness/policy.toml`, rendered by `scripts/harness_policy.py`)`.

- [ ] **Step 3: tooling-dimensions.md**

At line 121, after "the compiled guard (`crates/ness/`)", add ", whose policy is `~/.config/ness/policy.toml` (decision 2026-10-17-ness-policy-as-data),".

- [ ] **Step 4: just recipe**

In `.config/just/rust.just`, after `ness-check-installed`, add:

```just
# Validates a candidate policy and prints the verdict diff against the active one (agent-runnable; `ness policy apply` is human-only)
[group('rust')]
ness-policy-check candidate:
    {{ env("HOME") }}/.local/bin/ness policy check {{ candidate }}
```

and extend the `ness-install` comment: `# ... Requires an applied policy in $HOME first: ness policy apply ~/.config/ness/policy.toml`.

- [ ] **Step 5: corpus.rs module doc**

Change the line naming `crates/ness/tests/corpus/*.json` to `.config/ness/cases/*.json` (the guard cases now live with the policy; `hook_corpus/` is unchanged).

- [ ] **Step 6: Verify and commit**

Run: `cd $W && just lint` (markdown, just, shell gates) — expected clean.

```bash
git -C $W add .agents/skills/optimize-harness/SKILL.md .agents/skills/optimize-harness/references/harness-map.md docs/tooling-dimensions.md .config/just/rust.just crates/ness/tests/corpus.rs
git -C $W commit -m "docs(ness): point control-plane guidance at policy.toml and the proposal workflow" -- .agents/skills/optimize-harness/SKILL.md .agents/skills/optimize-harness/references/harness-map.md docs/tooling-dimensions.md .config/just/rust.just crates/ness/tests/corpus.rs
```

---

### Task 11: Full gate

- [ ] **Step 1: Run the repository gate from the worktree**

```bash
wt verify ness-policy-as-data
```

Expected: `just check` passes (lint, typecheck, spelling, harness-check, agentlink, ness-test, wt-test, bats). `harness-check` must show the Codex/omp permission cells unchanged.

- [ ] **Step 2: Confirm the git-checkout acceptance criterion**

In a scratch `$HOME` (not the real one):

```bash
h=$(mktemp -d); mkdir -p $h/.config/ness $h/.local/state/ness
cp ~/.config/ness/policy.toml $h/.config/ness/; cp -R ~/.config/ness/cases $h/.config/ness/
HOME=$h ~/.local/bin/ness policy apply --for-tests $h/.config/ness/policy.toml
printf '\n# edited after apply\n' >> $h/.config/ness/policy.toml
HOME=$h ~/.local/bin/ness guard --harness claude --tool bash --command ls
```

Expected: the last command prints `{"decision":"deny",...,"reason":"policy at .../policy.toml differs from the last apply; ..."}` and exits 2.

---

### Task 12: Retire the Plan

- [ ] **Step 1: Remove the Plan file**

```bash
git -C $W rm PLAN.md
```

- [ ] **Step 2: Commit removal of the Plan**

```bash
git -C $W commit -m "plan: done 2026-10-17-ness-policy-as-data" -- PLAN.md
```

- [ ] **Step 3: Record what shipped**

Not user-facing beyond this repository; no `CHANGELOG.md` exists here. The Decision stays `accepted`.
