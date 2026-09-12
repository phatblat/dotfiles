//! Repo and path resolution — transliterated from
//! `.agents/skills/git-worktree/wt.sh:72-128`.

use std::env;
use std::path::{Path, PathBuf};
use std::process::Command;

/// The symlink-resolved `$HOME`. `git rev-parse` and `git worktree list`
/// always report resolved paths, so every comparison against a repo root
/// must go through this rather than the raw `$HOME` env var.
pub fn home_real() -> PathBuf {
    let home = env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"));
    home.canonicalize().unwrap_or(home)
}

/// Resolves the repo root: `home_real` when `allow_home` (after verifying
/// it really is a git repo), otherwise the `--git-common-dir` of `repo` (or
/// cwd), with the trailing `/.git` stripped.
///
/// `--show-toplevel` is deliberately not used here: it reports the
/// *worktree's* root, which misfires from inside any worktree.
pub fn repo_root(allow_home: bool, repo: Option<&Path>, home_real: &Path) -> Result<PathBuf, i32> {
    if allow_home {
        let status = Command::new("git")
            .arg("-C")
            .arg(home_real)
            .args(["rev-parse", "--git-dir"])
            .output();
        let ok = matches!(status, Ok(o) if o.status.success());
        if !ok {
            eprintln!("wt: $HOME is not a git repository");
            return Err(4);
        }
        return Ok(home_real.to_path_buf());
    }

    let dir = repo
        .map(Path::to_path_buf)
        .or_else(|| env::current_dir().ok())
        .unwrap_or_else(|| PathBuf::from("."));

    let output = Command::new("git")
        .arg("-C")
        .arg(&dir)
        .args(["rev-parse", "--path-format=absolute", "--git-common-dir"])
        .output();

    let Ok(output) = output else {
        eprintln!("wt: not inside a git repository ({})", dir.display());
        return Err(4);
    };
    if !output.status.success() {
        eprintln!("wt: not inside a git repository ({})", dir.display());
        return Err(4);
    }

    let raw = String::from_utf8_lossy(&output.stdout);
    let raw = raw.trim();
    let root = raw.strip_suffix("/.git").unwrap_or(raw);
    Ok(PathBuf::from(root))
}

/// `"dotfiles"` when `repo_root == home_real`, else `repo_root` with the
/// `home_real/` prefix stripped and every `/` replaced by `-`. Kept for
/// parity with the shell implementations even though `wt_path` recomputes
/// the same logic inline; `overlay` looks manifests up by this value.
pub fn path_key(repo_root: &Path, home_real: &Path) -> String {
    if repo_root == home_real {
        return "dotfiles".to_string();
    }
    let stripped = repo_root
        .strip_prefix(home_real)
        .unwrap_or(repo_root)
        .to_string_lossy();
    stripped.replace('/', "-")
}

/// `${DOTFILES_WT_ROOT:-<home_real>/.worktrees/dotfiles}/<branch>` for the
/// dotfiles repo, else `<home_real>/.worktrees/<path_key>/<branch>`.
pub fn wt_path(repo_root: &Path, home_real: &Path, branch: &str) -> PathBuf {
    if repo_root == home_real {
        let root = env::var_os("DOTFILES_WT_ROOT")
            .map(PathBuf::from)
            .unwrap_or_else(|| home_real.join(".worktrees").join("dotfiles"));
        root.join(branch)
    } else {
        let key = path_key(repo_root, home_real);
        home_real.join(".worktrees").join(key).join(branch)
    }
}

/// One `git worktree list --porcelain` record.
struct WorktreeRecord {
    path: PathBuf,
    branch: Option<String>,
    detached: bool,
}

fn parse_worktree_list(root: &Path) -> Result<Vec<WorktreeRecord>, i32> {
    let output = Command::new("git")
        .arg("-C")
        .arg(root)
        .args(["worktree", "list", "--porcelain"])
        .output()
        .map_err(|_| 1)?;
    if !output.status.success() {
        return Err(1);
    }
    let text = String::from_utf8_lossy(&output.stdout);

    let mut records = Vec::new();
    let mut cur_path: Option<PathBuf> = None;
    let mut cur_branch: Option<String> = None;
    let mut cur_detached = false;

    let flush = |records: &mut Vec<WorktreeRecord>,
                 path: &mut Option<PathBuf>,
                 branch: &mut Option<String>,
                 detached: &mut bool| {
        if let Some(p) = path.take() {
            records.push(WorktreeRecord {
                path: p,
                branch: branch.take(),
                detached: *detached,
            });
        }
        *detached = false;
    };

    for line in text.lines() {
        if let Some(rest) = line.strip_prefix("worktree ") {
            flush(&mut records, &mut cur_path, &mut cur_branch, &mut cur_detached);
            cur_path = Some(PathBuf::from(rest));
        } else if let Some(rest) = line.strip_prefix("branch ") {
            cur_branch = Some(rest.strip_prefix("refs/heads/").unwrap_or(rest).to_string());
        } else if line == "detached" {
            cur_detached = true;
        } else if line.is_empty() {
            flush(&mut records, &mut cur_path, &mut cur_branch, &mut cur_detached);
        }
    }
    flush(&mut records, &mut cur_path, &mut cur_branch, &mut cur_detached);

    Ok(records)
}

/// Finds a worktree already registered for `refs/heads/<branch>` under
/// `repo_root`. Returns `Ok(None)` when there is none. Exits (returns
/// `Err(4)` after printing) when a registered worktree's leaf does not
/// match the branch — a mismatch is a defect to surface, never to silently
/// adopt.
pub fn find_registered(repo_root: &Path, branch: &str) -> Result<Option<PathBuf>, i32> {
    let records = parse_worktree_list(repo_root)?;
    let found = records
        .into_iter()
        .find(|r| r.branch.as_deref() == Some(branch));

    let Some(record) = found else {
        return Ok(None);
    };

    if record.path == repo_root {
        return Ok(Some(record.path));
    }

    let leaf_matches = record
        .path
        .file_name()
        .map(|n| n == branch)
        .unwrap_or(false);
    if !leaf_matches {
        eprintln!(
            "wt: registered worktree for {branch} has a mismatched directory"
        );
        eprintln!("  registered: {}", record.path.display());
        eprintln!("  expected to end in: /{branch}");
        return Err(4);
    }

    Ok(Some(record.path))
}

/// The first `worktree ` record — git always lists the main worktree first.
pub fn main_worktree(repo_root: &Path) -> Result<PathBuf, i32> {
    let records = parse_worktree_list(repo_root)?;
    records
        .into_iter()
        .next()
        .map(|r| r.path)
        .ok_or(1)
}

/// One `<path>\t<branch>` line per worktree, `(detached)` for detached
/// heads — matches `wt.sh:298-305`.
pub fn list_lines(repo_root: &Path) -> Result<Vec<String>, i32> {
    let records = parse_worktree_list(repo_root)?;
    Ok(records
        .into_iter()
        .map(|r| {
            let branch = if r.detached {
                "(detached)".to_string()
            } else {
                r.branch.unwrap_or_default()
            };
            format!("{}\t{}", r.path.display(), branch)
        })
        .collect())
}

pub fn worktree_prune(repo_root: &Path) {
    let _ = Command::new("git")
        .arg("-C")
        .arg(repo_root)
        .args(["worktree", "prune"])
        .status();
}
