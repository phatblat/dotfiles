//! Path helpers shared by `policy` and `manifest`.
//!
//! `ness` is installed once to `~/.local/bin/ness`, independent of any
//! checkout. `scripts/agent-harnesses.py` instead derives its dotfiles
//! checkout root by comparing its *own* file location to `$HOME`
//! (`scripts/agent-harnesses.py:81-83`), which is how it stays correct when
//! run from a linked git worktree of the same repo. A compiled binary has no
//! script location to compare, so `find_root` reproduces the same intent —
//! "which checkout is this invocation talking about" — by walking up from
//! the current working directory looking for a `.agents/harness` marker
//! directory, falling back to `$HOME` when none is found. This generalizes
//! rather than narrows the Python behavior: it is worktree-aware from any
//! subdirectory, not only from the two fixed levels above the script file.

use std::path::{Component, Path, PathBuf};

pub fn home_dir() -> PathBuf {
    match std::env::var("HOME") {
        Ok(home) if !home.is_empty() => PathBuf::from(home),
        _ => PathBuf::from("/"),
    }
}

fn process_cwd() -> PathBuf {
    std::env::current_dir().unwrap_or_else(|_| home_dir())
}

/// The dotfiles checkout root for this invocation. See module docs.
pub fn find_root() -> PathBuf {
    let mut dir = process_cwd();
    loop {
        if dir.join(".agents").join("harness").is_dir() {
            return dir;
        }
        match dir.parent() {
            Some(parent) => dir = parent.to_path_buf(),
            None => return home_dir(),
        }
    }
}

fn expand_tilde(path: &str, home: &Path) -> PathBuf {
    if path == "~" {
        return home.to_path_buf();
    }
    if let Some(rest) = path.strip_prefix("~/") {
        return home.join(rest);
    }
    PathBuf::from(path)
}

/// Resolve `.` and `..` textually, without touching the filesystem. Mirrors
/// the plan's explicit mandate (not `std::fs::canonicalize`, which errors on
/// a path that does not exist yet — the common case for a Write creating a
/// new file) and deliberately does not follow symlinks, unlike Python's
/// `Path.resolve(strict=False)`, which *does* resolve symlinks for path
/// components that happen to exist on disk. That nuance is not exercised by
/// the guard's regex rules (they match path text, not filesystem identity),
/// so pure lexical resolution is the correct, safer choice here.
fn lexical_normalize(path: &Path) -> PathBuf {
    let mut result = PathBuf::new();
    for component in path.components() {
        match component {
            Component::CurDir => {}
            Component::ParentDir => {
                // At an already-empty/root result, `pop` is a no-op, which
                // clamps `..` at the root exactly like `Path.resolve()` does.
                result.pop();
            }
            other => result.push(other.as_os_str()),
        }
    }
    result
}

/// Port of `normalize_path_for_matching` (`.agents/harness/hooks/safety.py:236-241`).
/// Relative paths resolve against the real process cwd (not `find_root()`):
/// that mirrors Python's `Path(expanded).resolve()`, which always resolves
/// against `os.getcwd()`, never against the guard's `--cwd` argument (that
/// argument is only used by `main_branch_commit_warning`'s git calls).
pub fn normalize_str(path: &str) -> String {
    if path.is_empty() {
        return String::new();
    }
    let home = home_dir();
    let expanded = expand_tilde(path, &home);
    let absolute = if expanded.is_absolute() {
        expanded
    } else {
        process_cwd().join(expanded)
    };
    lexical_normalize(&absolute).to_string_lossy().into_owned()
}
