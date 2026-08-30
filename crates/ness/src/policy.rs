//! Verbatim port of `.agents/harness/hooks/safety.py`.
//!
//! Every pattern below is copied character-for-character from the Python
//! source (re-anchored where Python's raw-string escaping of a literal
//! quote, e.g. `[\"']`, has no special regex meaning and is written here as
//! the equivalent `["']`). Do not hand-simplify a pattern that already
//! compiles — a transcription "cleanup" here is how a security rule quietly
//! stops matching. `fancy-regex` is used for every pattern (not just the
//! ones with lookaround) so the whole set stays copy-pasteable from the
//! Python source without engine-specific rewrites.
//!
//! `is_match` is a `Result` in `fancy-regex` because backtracking patterns
//! can in principle blow a resource limit. None of the patterns here are
//! adversarially explosive, but if one ever did error, `matches()` treats
//! that as "no match" — consistent with this module's broader fail-open
//! philosophy (a missing/unreadable manifest also fails open; see
//! `manifest.rs`).

use fancy_regex::Regex;
use std::sync::LazyLock;

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

fn matches(re: &Regex, text: &str) -> bool {
    re.is_match(text).unwrap_or(false)
}

// safety.py:26-29
static PRIVILEGE_ESCALATION: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)(^|;|&&|\|\||\||\n|\r|\$\(|`)\s*(sudo|su|doas|pkexec)\b").unwrap()
});

// safety.py:31-44
static DANGEROUS_COMMANDS: LazyLock<Vec<Regex>> = LazyLock::new(|| {
    vec![
        Regex::new(r"(?i)\brm\s+-(?=[A-Za-z-]*r)(?=[A-Za-z-]*f)[A-Za-z-]*\s+(/|~|\*|\.\.)")
            .unwrap(),
        Regex::new(r"(?i)>\s*/dev/sd[a-z]?").unwrap(),
        Regex::new(r"(?i)\bmkfs(\.|\s)").unwrap(),
        Regex::new(r"(?i)\bdd\s+if=.*\s+of=/dev/").unwrap(),
        Regex::new(r"(?i)\bchmod\s+(-R\s+)?777\b").unwrap(),
        Regex::new(r"(?i)\bchmod\s+\+s\b").unwrap(),
        Regex::new(r"(?i):\(\)\{.*:\|:&\};").unwrap(),
        Regex::new(r"(?i)\b(curl|wget)\b[^|]*\|\s*(ba)?sh\b").unwrap(),
        Regex::new(r"(?i)\b(truncate|shred)\b").unwrap(),
    ]
});

// safety.py:46-51
static OBFUSCATED_EXECUTION: LazyLock<Vec<Regex>> = LazyLock::new(|| {
    vec![
        Regex::new(r"(?i)\beval\s+.*\$").unwrap(),
        Regex::new(r"(?i)\bbase64\s+-d.*\|\s*(ba)?sh\b").unwrap(),
        Regex::new(r"(?i)\bawk\s+.*system\s*\(").unwrap(),
        Regex::new(r"(?i)\bbash\s+<\(").unwrap(),
    ]
});

// safety.py:53-78
static PROTECTED_PATHS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(
        r"(?i)(\.env($|\.)|\.ssh/|id_(rsa|ed25519|ecdsa)|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|\.aws/credentials|\.docker/config\.json|kubeconfig|\.npmrc$|\.pypirc$|\.netrc$|\.pgpass$|\.htpasswd$|\.git-credentials|\.claude/\.credentials\.json|\.codex/auth\.json|\.omp/agent/agent\.db|\.omp/agent/secrets\.yml|\.pi/agent/auth\.json|\.gemini/google_accounts\.json|\.gemini/oauth_creds\.json|\.gemini/antigravity-cli/installation_id|\.gemini/antigravity-cli/conversations/|\.cursor/ai-tracking/|\.grok/auth\.json|\.grok/mcp_credentials\.json|\.config/crush/crush\.json|\.local/share/crush/crush\.json|\.local/share/crush/crush\.db)",
    )
    .unwrap()
});

// safety.py:91-111. Kept as the same nine fragments currently in safety.py;
// if a human operator adds fragments there (see the "Close the control-plane
// gap" step in the de-risk plan), this list must be updated to match in the
// same change, or `just ness-parity` will start failing on those new cases.
static CONTROL_PLANE_FRAGMENTS: &[&str] = &[
    r"/\.agents/harness/hooks/",
    r"/\.agents/harness/self-improve-policy\.json(?![\w.-])",
    r"/\.agents/harness/generated-paths\.json(?![\w.-])",
    r"/scripts/agent-harnesses\.py(?![\w.-])",
    r"/scripts/agent_plugins\.py(?![\w.-])",
    r"/harness-guard\.(?:ts|py)(?![\w.-])",
    r"/(?:write|bash)-guard\.sh(?![\w.-])",
    r"/opencode/plugins/harness\.ts(?![\w.-])",
    r"/agent/extensions/harness\.ts(?![\w.-])",
    r"/harness-guard\.json(?![\w.-])",
];

// safety.py:104-107
static CONTROL_PLANE_PATHS: LazyLock<Regex> = LazyLock::new(|| {
    let joined = format!("(?i)(?:{})", CONTROL_PLANE_FRAGMENTS.join("|"));
    Regex::new(&joined).unwrap()
});

// safety.py:109-121
static SECRET_CONTENT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(
        r#"(?i)(AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|glpat-[A-Za-z0-9_-]{20,}|xox[bpoas]-[A-Za-z0-9-]+|-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----|password\s*[:=]\s*["'][^"']{8,}["'])"#,
    )
    .unwrap()
});

// safety.py:198
static REDIRECT_TARGET: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r">>?\s*(?P<span>[^\s;|&<>]+)").unwrap());

// safety.py:199-203
static MUTATING_ARGV: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(
        r"(?i)\b(?:rm|mv|cp|tee|ln|install|truncate|shred|unlink|touch|chmod|chown)\b(?P<span>[^;|&]*)",
    )
    .unwrap()
});

// safety.py:204
static SED_INPLACE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"(?i)\bsed\b(?P<span>[^;|&]*?-i(?:\S*)?[^;|&]*)").unwrap());

// safety.py:205
static DD_TARGET: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"(?i)\bdd\b[^;|&]*?\bof=(?P<span>[^\s;|&]+)").unwrap());

// safety.py:207
static PATH_TOKEN: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r#"[^\s;|&<>'"]*[/~][^\s;|&<>'"]*"#).unwrap());

// safety.py:244 (main_branch_commit_warning's own match; deliberately no
// IGNORECASE, matching the Python source exactly)
static COMMIT_COMMAND: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^\s*(git\s+commit|git\s+-C\s+\S+\s+commit)\b").unwrap());

/// Port of `evaluate` (safety.py:124-139).
pub fn evaluate(tool: &str, command: &str, path: &str, content: &str, cwd: &str) -> GuardDecision {
    let normalized_tool = tool.to_lowercase();
    let normalized_tool = normalized_tool.trim();
    match normalized_tool {
        "bash" | "shell" | "exec" => evaluate_command(command, cwd),
        "write" | "edit" | "file_write" | "file_edit" => evaluate_write(path, content),
        _ => GuardDecision::allow(),
    }
}

/// Port of `evaluate_command` (safety.py:142-174).
pub fn evaluate_command(command: &str, cwd: &str) -> GuardDecision {
    if command.trim().is_empty() {
        return GuardDecision::allow();
    }

    if matches(&PRIVILEGE_ESCALATION, command) {
        return GuardDecision::deny("Privilege escalation blocked");
    }

    if DANGEROUS_COMMANDS.iter().any(|p| matches(p, command)) {
        return GuardDecision::deny("Dangerous command pattern detected");
    }

    if OBFUSCATED_EXECUTION.iter().any(|p| matches(p, command)) {
        return GuardDecision::deny("Obfuscated execution pattern detected");
    }

    let target = writes_to(command, &PROTECTED_PATHS);
    if !target.is_empty() {
        return GuardDecision::deny(format!("protected file blocked: {target}"));
    }

    let target = writes_to(command, &CONTROL_PLANE_PATHS);
    if !target.is_empty() {
        return GuardDecision::deny(format!(
            "control-plane file is human-only: {target}. It decides what the guard permits, so edit it directly rather than through an agent."
        ));
    }

    let warning = main_branch_commit_warning(command, cwd);
    if !warning.is_empty() {
        return GuardDecision::warn(warning);
    }

    GuardDecision::allow()
}

/// Port of `evaluate_write` (safety.py:177-192).
pub fn evaluate_write(path: &str, content: &str) -> GuardDecision {
    if !path.is_empty() {
        let normalized = crate::paths::normalize_str(path);
        if matches(&PROTECTED_PATHS, &normalized) {
            return GuardDecision::deny(format!("protected file blocked: {path}"));
        }
        if matches(&CONTROL_PLANE_PATHS, &normalized) {
            return GuardDecision::deny(format!(
                "control-plane file is human-only: {path}. It decides what the guard permits, so edit it directly rather than through an agent."
            ));
        }
    }

    if !content.is_empty() && matches(&SECRET_CONTENT, content) {
        return GuardDecision::deny("secret-like content detected");
    }

    GuardDecision::allow()
}

/// Port of `candidate_write_targets` (safety.py:210-224).
pub fn candidate_write_targets(command: &str) -> Vec<String> {
    let mut targets: Vec<String> = Vec::new();
    for pattern in [&*REDIRECT_TARGET, &*MUTATING_ARGV, &*SED_INPLACE, &*DD_TARGET] {
        for caps in pattern.captures_iter(command) {
            let Ok(caps) = caps else { continue };
            let Some(span) = caps.name("span") else { continue };
            for tok in PATH_TOKEN.find_iter(span.as_str()).flatten() {
                targets.push(tok.as_str().to_string());
            }
        }
    }
    targets
        .into_iter()
        .map(|t| t.trim_matches(|c| c == '\'' || c == '"').to_string())
        .filter(|t| !t.is_empty())
        .collect()
}

/// Port of `writes_to` (safety.py:227-233).
pub fn writes_to(command: &str, pattern: &Regex) -> String {
    for target in candidate_write_targets(command) {
        if matches(pattern, &crate::paths::normalize_str(&target)) {
            return target;
        }
    }
    String::new()
}

/// Port of `main_branch_commit_warning` (safety.py:244-266). `cwd == ""`
/// falls back to the real process cwd, matching Python's `cwd or
/// os.getcwd()` — distinct from the CLI layer's default of `find_root()`
/// when `--cwd` is omitted entirely (`parse_guard_args`' `"cwd": str(ROOT)`).
pub fn main_branch_commit_warning(command: &str, cwd: &str) -> String {
    if !matches(&COMMIT_COMMAND, command) {
        return String::new();
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
        return String::new();
    }

    let repo_root = run_git(&["rev-parse", "--show-toplevel"], workdir);
    let commit_count = run_git(&["rev-list", "--count", "HEAD"], workdir);
    let home = crate::paths::home_dir().to_string_lossy().into_owned();
    let commits: i64 = commit_count.parse().unwrap_or(0);

    if repo_root != home && commits >= 100 {
        return format!(
            "WARNING: You are on the protected '{branch}' branch. Create a feature branch before committing."
        );
    }
    String::new()
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
