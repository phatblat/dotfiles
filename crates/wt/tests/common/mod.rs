//! Shared fixture helpers for `wt`'s integration tests, porting
//! `tests/wt.bats:12-46`. Compiled once per integration-test binary, so not
//! every helper is exercised by every binary.
#![allow(dead_code)]

use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicUsize, Ordering};

static COUNTER: AtomicUsize = AtomicUsize::new(0);

pub fn built_wt() -> PathBuf {
    PathBuf::from(env!("CARGO_BIN_EXE_wt"))
}

/// A fresh scratch directory under the system temp dir, unique per call.
pub fn tmp_dir(label: &str) -> PathBuf {
    let n = COUNTER.fetch_add(1, Ordering::SeqCst);
    let dir = std::env::temp_dir().join(format!(
        "wt-test-{}-{}-{}",
        std::process::id(),
        n,
        label
    ));
    std::fs::create_dir_all(&dir).expect("create tmp dir");
    dir.canonicalize().expect("canonicalize tmp dir")
}

fn git(dir: &Path, args: &[&str]) {
    let status = Command::new("git")
        .arg("-C")
        .arg(dir)
        .args(args)
        .status()
        .unwrap_or_else(|e| panic!("git {args:?} in {}: {e}", dir.display()));
    assert!(status.success(), "git {args:?} in {} failed", dir.display());
}

fn git_output(dir: &Path, args: &[&str]) -> String {
    let output = Command::new("git")
        .arg("-C")
        .arg(dir)
        .args(args)
        .output()
        .unwrap_or_else(|e| panic!("git {args:?} in {}: {e}", dir.display()));
    assert!(output.status.success(), "git {args:?} in {} failed", dir.display());
    String::from_utf8_lossy(&output.stdout).trim().to_string()
}

pub struct Fixture {
    pub root: PathBuf,
    pub remote: PathBuf,
    pub seed: PathBuf,
    pub clone: PathBuf,
    pub fake_home: PathBuf,
    pub branch: String,
    pub remote_head: String,
}

/// Port of `tests/wt.bats:12-35`'s `setup()`.
pub fn fixture() -> Fixture {
    let root = tmp_dir("fixture");
    let remote = root.join("remote.git");
    let seed = root.join("seed");
    let clone = root.join("clone");
    let fake_home = root.join("home");
    let branch = "ben/dxo-204/codex-attribution".to_string();

    std::fs::create_dir_all(&remote).unwrap();
    git(&remote, &["init", "--bare", "-q"]);

    std::fs::create_dir_all(&seed).unwrap();
    git(&seed, &["init", "-q", "-b", "main"]);
    git(&seed, &["config", "user.email", "test@example.com"]);
    git(&seed, &["config", "user.name", "Test"]);
    std::fs::write(seed.join("README"), "main\n").unwrap();
    git(&seed, &["add", "README"]);
    git(&seed, &["commit", "-qm", "main"]);
    git(&seed, &["remote", "add", "origin", remote.to_str().unwrap()]);
    git(&seed, &["push", "-qu", "origin", "main"]);

    git(&root, &["clone", "-q", remote.to_str().unwrap(), clone.to_str().unwrap()]);

    git(&seed, &["switch", "-qc", &branch]);
    std::fs::write(seed.join("README"), "remote branch\n").unwrap();
    git(&seed, &["commit", "-qam", "remote"]);
    let remote_head = git_output(&seed, &["rev-parse", "HEAD"]);
    git(&seed, &["push", "-qu", "origin", &branch]);

    std::fs::create_dir_all(&fake_home).unwrap();

    Fixture {
        root,
        remote,
        seed,
        clone,
        fake_home,
        branch,
        remote_head,
    }
}

/// Port of `tests/wt.bats:39-46`'s `init_dotfiles_home`.
pub fn init_dotfiles_home(fake_home: &Path) {
    git(fake_home, &["init", "-q"]);
    git(fake_home, &["config", "user.email", "test@example.com"]);
    git(fake_home, &["config", "user.name", "Test"]);
    std::fs::write(fake_home.join("README"), "home\n").unwrap();
    git(fake_home, &["add", "README"]);
    git(fake_home, &["commit", "-qm", "home"]);
}

pub fn worktree_list_porcelain(repo: &Path) -> String {
    git_output(repo, &["worktree", "list", "--porcelain"])
}

/// Finds the worktree path registered for `refs/heads/<branch>`.
pub fn find_worktree(repo: &Path, branch: &str) -> Option<PathBuf> {
    let out = worktree_list_porcelain(repo);
    let mut cur: Option<String> = None;
    for line in out.lines() {
        if let Some(rest) = line.strip_prefix("worktree ") {
            cur = Some(rest.to_string());
        } else if let Some(rest) = line.strip_prefix("branch ") {
            if rest == format!("refs/heads/{branch}") {
                return cur.clone().map(PathBuf::from);
            }
        }
    }
    None
}

pub fn wt_cmd(home: &Path) -> Command {
    let mut cmd = Command::new(built_wt());
    cmd.env_clear();
    cmd.env("HOME", home);
    if let Ok(path) = std::env::var("PATH") {
        cmd.env("PATH", path);
    }
    cmd
}
