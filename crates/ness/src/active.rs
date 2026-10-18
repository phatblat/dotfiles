//! The active policy: `~/.config/ness/policy.toml` verified against
//! `~/.local/state/ness/applied.json`, the record a human wrote with
//! `ness policy apply`. Every failure here is a reason string that becomes
//! a deny on every verdict (decision 2026-10-17-ness-policy-as-data,
//! clauses 2 and 3).

use crate::policy_file::{self, Compiled};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;
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

pub fn sha256_bytes(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

/// Hash of a file on disk. `ness policy apply` must hash the same bytes it
/// validated (read once, then `sha256_bytes` + `load_candidate_text`),
/// not call this on a path it validated separately.
pub fn sha256_file(path: &Path) -> Result<String, String> {
    let bytes = std::fs::read(path).map_err(|e| format!("read {}: {e}", path.display()))?;
    Ok(sha256_bytes(&bytes))
}

pub fn read_applied(path: &Path) -> Result<Applied, String> {
    let text =
        std::fs::read_to_string(path).map_err(|e| format!("read {}: {e}", path.display()))?;
    serde_json::from_str(&text).map_err(|e| format!("parse {}: {e}", path.display()))
}

pub fn check_required_protection(p: &Compiled) -> Result<(), String> {
    for path in REQUIRED_PROTECTED_PATHS {
        let normalized = crate::paths::normalize_lexical(path);
        match p.control_plane.is_match(&normalized) {
            Ok(true) => {}
            Ok(false) => return Err(format!("[control_plane] must cover {path} ({normalized})")),
            Err(e) => return Err(format!("policy pattern error: {e}")),
        }
    }
    let mut denied = false;
    for re in &p.dangerous {
        if re
            .is_match(REQUIRED_DENIED_COMMAND)
            .map_err(|e| format!("policy pattern error: {e}"))?
        {
            denied = true;
            break;
        }
    }
    if !denied {
        return Err(format!(
            "[commands.dangerous] must deny `{REQUIRED_DENIED_COMMAND}`"
        ));
    }
    Ok(())
}

/// Parse, compile, and invariant-check policy text: what `ness policy
/// check` does to a candidate.
pub fn load_candidate_text(text: &str) -> Result<Compiled, String> {
    let compiled = policy_file::parse(text)?.compile()?;
    check_required_protection(&compiled)?;
    Ok(compiled)
}

pub fn load_from(policy: &Path, applied: &Path) -> Result<Compiled, String> {
    let remedy = "run `ness policy check` and have a human run `ness policy apply`";
    if !policy.is_file() {
        return Err(format!("policy missing at {}; {remedy}", policy.display()));
    }
    // Read once: the bytes that are hashed are the bytes that are parsed.
    let bytes =
        std::fs::read(policy).map_err(|e| format!("read {}: {e}; {remedy}", policy.display()))?;
    let actual = sha256_bytes(&bytes);
    let record = read_applied(applied).map_err(|e| {
        format!(
            "policy at {} is not applied ({e}); {remedy}",
            policy.display()
        )
    })?;
    if record.policy_sha256 != actual {
        return Err(format!(
            "policy at {} differs from the last apply; {remedy}",
            policy.display()
        ));
    }
    let text = String::from_utf8(bytes)
        .map_err(|e| format!("policy at {} is not UTF-8: {e}; {remedy}", policy.display()))?;
    load_candidate_text(&text).map_err(|e| format!("{e}; {remedy}"))
}

/// The guard's entry point: the active policy or the reason every verdict
/// is a deny.
pub fn load() -> Result<Compiled, String> {
    load_from(&crate::paths::policy_path(), &crate::paths::applied_path())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};

    static N: AtomicUsize = AtomicUsize::new(0);

    /// A throwaway `$HOME` layout, removed on drop.
    struct TempHome(std::path::PathBuf);

    impl std::ops::Deref for TempHome {
        type Target = Path;
        fn deref(&self) -> &Path {
            &self.0
        }
    }

    impl Drop for TempHome {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(&self.0);
        }
    }

    fn temp_home() -> TempHome {
        let d = std::env::temp_dir().join(format!(
            "ness-active-{}-{}",
            std::process::id(),
            N.fetch_add(1, Ordering::SeqCst)
        ));
        std::fs::create_dir_all(d.join(".config/ness/cases")).unwrap();
        std::fs::create_dir_all(d.join(".local/state/ness")).unwrap();
        TempHome(d)
    }

    fn write_applied(home: &Path, policy: &Path) {
        let applied = Applied {
            policy_sha256: sha256_file(policy).unwrap(),
            applied_at: "x".into(),
            cases: BTreeMap::new(),
        };
        std::fs::write(
            home.join(".local/state/ness/applied.json"),
            serde_json::to_string(&applied).unwrap(),
        )
        .unwrap();
    }

    fn fixture() -> String {
        std::fs::read_to_string(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/policy.toml"
        ))
        .unwrap()
    }

    #[test]
    fn missing_policy_is_an_error_naming_the_path() {
        let home = temp_home();
        let err = load_from(
            &home.join(".config/ness/policy.toml"),
            &home.join(".local/state/ness/applied.json"),
        )
        .unwrap_err();
        assert!(
            err.contains("policy.toml") && err.contains("ness policy check"),
            "{err}"
        );
    }

    #[test]
    fn unapplied_policy_is_an_error() {
        let home = temp_home();
        std::fs::write(home.join(".config/ness/policy.toml"), fixture()).unwrap();
        let err = load_from(
            &home.join(".config/ness/policy.toml"),
            &home.join(".local/state/ness/applied.json"),
        )
        .unwrap_err();
        assert!(err.contains("not applied"), "{err}");
    }

    #[test]
    fn hash_mismatch_is_an_error() {
        let home = temp_home();
        let policy = home.join(".config/ness/policy.toml");
        std::fs::write(&policy, fixture()).unwrap();
        let applied = Applied {
            policy_sha256: "0".repeat(64),
            applied_at: "x".into(),
            cases: Default::default(),
        };
        std::fs::write(
            home.join(".local/state/ness/applied.json"),
            serde_json::to_string(&applied).unwrap(),
        )
        .unwrap();
        let err = load_from(&policy, &home.join(".local/state/ness/applied.json")).unwrap_err();
        assert!(err.contains("differs from the last apply"), "{err}");
    }

    #[test]
    fn applied_policy_loads() {
        let home = temp_home();
        let policy = home.join(".config/ness/policy.toml");
        std::fs::write(&policy, fixture()).unwrap();
        write_applied(&home, &policy);
        let c = load_from(&policy, &home.join(".local/state/ness/applied.json")).unwrap();
        assert_eq!(c.dangerous.len(), 2);
    }

    #[test]
    fn malformed_applied_is_not_applied() {
        let home = temp_home();
        let policy = home.join(".config/ness/policy.toml");
        std::fs::write(&policy, fixture()).unwrap();
        std::fs::write(home.join(".local/state/ness/applied.json"), "{not json").unwrap();
        let err = load_from(&policy, &home.join(".local/state/ness/applied.json")).unwrap_err();
        assert!(err.contains("not applied"), "{err}");
    }

    #[test]
    fn applied_but_uncompilable_policy_is_an_error_with_remedy() {
        let home = temp_home();
        let policy = home.join(".config/ness/policy.toml");
        let text = fixture().replace(r"'/\.local/bin/ness(?![\w.-])'", "'['");
        assert_ne!(text, fixture());
        std::fs::write(&policy, text).unwrap();
        write_applied(&home, &policy);
        let err = load_from(&policy, &home.join(".local/state/ness/applied.json")).unwrap_err();
        assert!(err.contains("ness policy check"), "{err}");
    }

    #[test]
    fn required_protection_message_names_normalized_path() {
        let text = fixture().replace(r"'/\.config/ness/policy\.toml(?![\w.-])', ", "");
        let c = crate::policy_file::parse(&text).unwrap().compile().unwrap();
        let err = check_required_protection(&c).unwrap_err();
        let normalized = crate::paths::normalize_lexical("~/.config/ness/policy.toml");
        assert!(err.contains(&normalized), "{err}");
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
