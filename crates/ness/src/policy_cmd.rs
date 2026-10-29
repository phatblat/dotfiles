//! `ness policy check|apply|active` (decision 2026-10-17-ness-policy-as-data,
//! clauses 5-8). `check` is agent-runnable; `apply` is the one human action.

use crate::active::{self, Applied};
use crate::guard_eval::evaluate_with_manifest;
use crate::paths;
use crate::policy_file::Compiled;
use serde_json::Value;
use std::collections::BTreeMap;
use std::io::{BufRead, IsTerminal, Write};
use std::path::{Path, PathBuf};

struct Case {
    name: String,
    value: Value,
    /// sha256 of the bytes that were parsed, so what `apply` records is
    /// exactly what `check` evaluated.
    sha256: String,
}

/// A missing directory is an empty corpus; any other error propagates.
fn load_cases(dir: &Path) -> Result<Vec<Case>, String> {
    let mut cases = Vec::new();
    let rd = match std::fs::read_dir(dir) {
        Ok(rd) => rd,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(cases),
        Err(e) => return Err(format!("read {}: {e}", dir.display())),
    };
    for entry in rd {
        let entry = entry.map_err(|e| format!("read {}: {e}", dir.display()))?;
        let name = entry.file_name().to_string_lossy().into_owned();
        if !name.ends_with(".json") {
            continue;
        }
        let bytes = std::fs::read(entry.path()).map_err(|e| format!("read {name}: {e}"))?;
        let value: Value =
            serde_json::from_slice(&bytes).map_err(|e| format!("parse {name}: {e}"))?;
        let sha256 = active::sha256_bytes(&bytes);
        cases.push(Case {
            name,
            value,
            sha256,
        });
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
        if c.is_empty() {
            paths::find_root().to_string_lossy().into_owned()
        } else {
            c.to_string()
        }
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
    /// Case digests as seen by this check; `apply` records exactly these so
    /// the delta it showed and the delta it accepts are the same snapshot.
    case_digests: BTreeMap<String, String>,
}

impl CheckReport {
    fn exit_code(&self) -> i32 {
        if self.errors.is_empty()
            && self.failures.is_empty()
            && self.removed.is_empty()
            && self.changed.is_empty()
        {
            0
        } else {
            1
        }
    }
    fn only_case_changes(&self) -> bool {
        self.errors.is_empty()
            && self.failures.is_empty()
            && !(self.removed.is_empty() && self.changed.is_empty())
    }
}

/// Reads the candidate once and returns the report together with the exact
/// bytes that were validated, so `apply` installs and hashes those bytes and
/// nothing that could have changed on disk in between.
fn run_check(candidate: &Path, out: &mut dyn Write) -> Result<(CheckReport, Vec<u8>), String> {
    let mut r = CheckReport {
        errors: vec![],
        failures: vec![],
        diff: vec![],
        added: vec![],
        removed: vec![],
        changed: vec![],
        active_err: None,
        case_digests: BTreeMap::new(),
    };
    let bytes =
        std::fs::read(candidate).map_err(|e| format!("read {}: {e}", candidate.display()))?;
    let compiled = match std::str::from_utf8(&bytes)
        .map_err(|e| format!("read {}: {e}", candidate.display()))
        .and_then(active::load_candidate_text)
    {
        Ok(c) => c,
        Err(e) => {
            r.errors.push(e);
            writeln!(out, "schema: {}", r.errors[0]).ok();
            return Ok((r, bytes));
        }
    };
    writeln!(out, "schema: ok").ok();
    writeln!(out, "invariants: ok").ok();

    let cases_dir = paths::cases_dir();
    let cases = load_cases(&cases_dir)?;
    let applied = active::read_applied(&paths::applied_path());
    if cases.is_empty() && applied.is_err() {
        let e = format!(
            "no cases in {} and no previous apply; refusing to bootstrap with an empty corpus",
            cases_dir.display()
        );
        writeln!(out, "cases: {e}").ok();
        r.errors.push(e);
        return Ok((r, bytes));
    }
    let active = active::load();
    for c in &cases {
        let (dec, reason) = verdict(&compiled, &c.value);
        let exp_dec = str_field(&c.value["expected"], "decision");
        let exp_reason = str_field(&c.value["expected"], "reason");
        if dec != exp_dec || reason != exp_reason {
            r.failures.push(format!(
                "{}: expected {exp_dec} {exp_reason:?}; got {dec} {reason:?}",
                c.name
            ));
        }
        if let Ok(a) = &active {
            let (adec, areason) = verdict(a, &c.value);
            if adec != dec || areason != reason {
                r.diff.push(format!(
                    "{}: {adec} {areason:?} -> {dec} {reason:?}",
                    c.name
                ));
            }
        }
    }
    if let Err(e) = &active {
        r.active_err = Some(e.clone());
    }
    writeln!(
        out,
        "cases: {} run, {} failed",
        cases.len(),
        r.failures.len()
    )
    .ok();
    for f in &r.failures {
        writeln!(out, "  {f}").ok();
    }
    if let Some(e) = &r.active_err {
        writeln!(
            out,
            "verdict diff: skipped (active policy not loadable: {e})"
        )
        .ok();
    } else {
        writeln!(out, "verdict diff: {} case(s)", r.diff.len()).ok();
        for d in &r.diff {
            writeln!(out, "  {d}").ok();
        }
    }

    r.case_digests = cases
        .iter()
        .map(|c| (c.name.clone(), c.sha256.clone()))
        .collect();
    let then = applied.map(|a| a.cases).unwrap_or_default();
    for (name, h) in &r.case_digests {
        match then.get(name) {
            None => r.added.push(name.clone()),
            Some(old) if old != h => r.changed.push(name.clone()),
            _ => {}
        }
    }
    for name in then.keys() {
        if !r.case_digests.contains_key(name) {
            r.removed.push(name.clone());
        }
    }
    writeln!(
        out,
        "case delta since last apply: {} added, {} removed, {} changed",
        r.added.len(),
        r.removed.len(),
        r.changed.len()
    )
    .ok();
    for n in &r.added {
        writeln!(out, "  added: {n}").ok();
    }
    for n in &r.removed {
        writeln!(out, "  removed: {n}").ok();
    }
    for n in &r.changed {
        writeln!(out, "  changed: {n}").ok();
    }
    Ok((r, bytes))
}

pub fn check(candidate: &Path) -> i32 {
    let mut stdout = std::io::stdout();
    match run_check(candidate, &mut stdout) {
        Ok((r, _)) => r.exit_code(),
        Err(e) => {
            eprintln!("ness policy check: {e}");
            2
        }
    }
}

/// Writes `bytes` to a fresh `.<name>.<pid>.tmp` beside `target` (refusing a
/// pre-existing file of that name, so nothing planted there is renamed into
/// place) and renames it over `target`. A temp file this call created is
/// removed on any later error; a pre-existing one is left for inspection.
fn write_then_rename(bytes: &[u8], target: &Path) -> Result<(), String> {
    let dir = target
        .parent()
        .ok_or_else(|| format!("{} has no parent", target.display()))?;
    let name = target
        .file_name()
        .ok_or_else(|| format!("{} has no file name", target.display()))?
        .to_string_lossy();
    let tmp = dir.join(format!(".{name}.{}.tmp", std::process::id()));
    let mut file = std::fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&tmp)
        .map_err(|e| format!("write {}: {e}", tmp.display()))?;
    let result = file
        .write_all(bytes)
        .and_then(|_| file.sync_all())
        .map_err(|e| format!("write {}: {e}", tmp.display()))
        .and_then(|_| {
            std::fs::rename(&tmp, target)
                .map_err(|e| format!("rename to {}: {e}", target.display()))
        });
    if result.is_err() {
        std::fs::remove_file(&tmp).ok();
    }
    result
}

/// Installs the validated policy bytes at `target` and records them (plus
/// the case digests the check evaluated) at `applied`. Writing the bytes in
/// memory rather than copying the candidate path also covers the bootstrap
/// case where the candidate *is* the target.
fn install(
    bytes: &[u8],
    cases: BTreeMap<String, String>,
    target: &Path,
    applied: &Path,
) -> Result<(), String> {
    for dir in [target.parent().unwrap(), applied.parent().unwrap()] {
        std::fs::create_dir_all(dir).map_err(|e| format!("create {}: {e}", dir.display()))?;
    }
    write_then_rename(bytes, target)?;
    let record = Applied {
        policy_sha256: active::sha256_bytes(bytes),
        applied_at: chrono_free_now(),
        cases,
    };
    write_then_rename(
        serde_json::to_string_pretty(&record).unwrap().as_bytes(),
        applied,
    )
}

/// RFC 3339 UTC without pulling in a date crate.
fn chrono_free_now() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
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

pub fn apply(candidate: &Path, accept_case_changes: bool) -> i32 {
    if !std::io::stdin().is_terminal() {
        eprintln!("ness policy apply: requires a terminal on stdin; a human runs this");
        return 2;
    }
    // A PTY satisfies `is_terminal()`, so the TTY check alone does not prove
    // a human. `sudo -k -v` ignores cached credentials and demands a fresh
    // factor (password, or Touch ID via pam_tid) that no tool input supplies.
    match std::process::Command::new("sudo")
        .args(["-k", "-v"])
        .status()
    {
        Ok(s) if s.success() => {}
        Ok(_) => {
            eprintln!("ness policy apply: sudo authentication failed; a human applies policy");
            return 2;
        }
        Err(e) => {
            eprintln!("ness policy apply: cannot run sudo -v: {e}");
            return 2;
        }
    }
    let mut buf: Vec<u8> = Vec::new();
    let (report, bytes) = match run_check(candidate, &mut buf) {
        Ok(r) => r,
        Err(e) => {
            eprintln!("ness policy apply: {e}");
            return 2;
        }
    };
    print!("{}", String::from_utf8_lossy(&buf));
    let case_changes = report.exit_code() != 0;
    if case_changes && !(report.only_case_changes() && accept_case_changes) {
        eprintln!(
            "ness policy apply: refusing; fix the failures above{}",
            if report.only_case_changes() {
                " or pass --accept-case-changes"
            } else {
                ""
            }
        );
        return 1;
    }
    // Always confirm: a candidate that passes every existing case can still
    // weaken the guard on an input no case covers.
    print!(
        "Install {} as the active policy{}? Type yes: ",
        candidate.display(),
        if case_changes {
            " and accept the removed/changed cases listed above"
        } else {
            ""
        }
    );
    std::io::stdout().flush().ok();
    let mut line = String::new();
    std::io::stdin().lock().read_line(&mut line).ok();
    if line.trim() != "yes" {
        eprintln!("ness policy apply: not confirmed");
        return 1;
    }
    let target = paths::policy_path();
    if let Err(e) = install(&bytes, report.case_digests, &target, &paths::applied_path()) {
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
    let action = args.first().map(String::as_str);
    let allowed_flags: &[&str] = match action {
        Some("apply") => &["--accept-case-changes"],
        _ => &[],
    };
    if let Some(flag) = args
        .iter()
        .skip(1)
        .find(|a| a.starts_with("--") && !allowed_flags.contains(&a.as_str()))
    {
        eprintln!(
            "ness policy: unknown flag '{flag}' for '{}'",
            action.unwrap_or("active")
        );
        return 2;
    }
    let positional: Vec<&String> = args
        .iter()
        .skip(1)
        .filter(|a| !a.starts_with("--"))
        .collect();
    match action {
        None | Some("active") => active_cmd(),
        Some("check") => {
            let candidate = positional
                .first()
                .map(PathBuf::from)
                .unwrap_or_else(paths::policy_path);
            check(&candidate)
        }
        Some("apply") => {
            let accept = args.iter().any(|a| a == "--accept-case-changes");
            let candidate = positional
                .first()
                .map(PathBuf::from)
                .unwrap_or_else(paths::policy_path);
            apply(&candidate, accept)
        }
        Some(other) => {
            eprintln!("ness policy: unknown action '{other}' (expected check, apply, or active)");
            2
        }
    }
}

#[cfg(test)]
mod tests {
    use super::install;
    use crate::active;
    use std::collections::BTreeMap;
    use std::path::PathBuf;
    use std::sync::atomic::{AtomicUsize, Ordering};

    static N: AtomicUsize = AtomicUsize::new(0);

    struct Scratch(PathBuf);
    impl Drop for Scratch {
        fn drop(&mut self) {
            std::fs::remove_dir_all(&self.0).ok();
        }
    }

    fn scratch() -> Scratch {
        let d = std::env::temp_dir().join(format!(
            "ness-install-test-{}-{}",
            std::process::id(),
            N.fetch_add(1, Ordering::SeqCst)
        ));
        std::fs::create_dir_all(&d).unwrap();
        Scratch(d)
    }

    fn digests() -> BTreeMap<String, String> {
        BTreeMap::from([("001-a.json".to_string(), "abc".to_string())])
    }

    #[test]
    fn install_writes_policy_and_applied_record() {
        let s = scratch();
        let target = s.0.join(".config/ness/policy.toml");
        let applied = s.0.join(".local/state/ness/applied.json");
        let bytes = b"[control_plane]\npatterns = []\n";
        install(bytes, digests(), &target, &applied).unwrap();
        assert_eq!(std::fs::read(&target).unwrap(), bytes);
        let record = active::read_applied(&applied).unwrap();
        assert_eq!(record.policy_sha256, active::sha256_bytes(bytes));
        assert_eq!(record.cases, digests());
        assert!(record.applied_at.ends_with('Z'), "{}", record.applied_at);
        assert!(!s
            .0
            .join(".config/ness")
            .join(format!(".policy.toml.{}.tmp", std::process::id()))
            .exists());
    }

    #[test]
    fn install_refuses_planted_temp_file_and_leaves_target_alone() {
        let s = scratch();
        let dir = s.0.join(".config/ness");
        std::fs::create_dir_all(&dir).unwrap();
        let target = dir.join("policy.toml");
        std::fs::write(&target, b"old").unwrap();
        let planted = dir.join(format!(".policy.toml.{}.tmp", std::process::id()));
        std::fs::write(&planted, b"planted").unwrap();
        let applied = s.0.join(".local/state/ness/applied.json");
        let err = install(b"new", digests(), &target, &applied).unwrap_err();
        assert!(err.contains("write"), "{err}");
        assert_eq!(std::fs::read(&target).unwrap(), b"old");
        assert!(!applied.exists());
        // The planted file is not ours to remove: it was never opened.
        assert_eq!(std::fs::read(&planted).unwrap(), b"planted");
    }
}
