//! The nine `wt` actions — transliterated from
//! `.agents/skills/git-worktree/wt.sh` and `.config/zsh/functions/wt`.

use crate::overlay;
use crate::repo;
use crate::Args;
use std::env;
use std::fs;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

/// Files checked by the ancestor-config warning — ported from
/// `_wt_ancestor_warn` (`.config/zsh/functions/wt:13-21`).
const ANCESTOR_FILES: &[&str] = &[".config/mise/config.toml", ".editorconfig", ".envrc"];

fn ancestor_warn(home_real: &Path, wt: &Path) {
    for f in ANCESTOR_FILES {
        let home_file = home_real.join(f);
        let wt_file = wt.join(f);
        if !home_file.is_file() || !wt_file.is_file() {
            continue;
        }
        let (a, b) = match (fs::read(&home_file), fs::read(&wt_file)) {
            (Ok(a), Ok(b)) => (a, b),
            _ => continue,
        };
        if a != b {
            eprintln!("warning: {f} differs between this worktree and $HOME;");
            eprintln!("         tools that search parent directories may use the $HOME copy.");
        }
    }
}

fn dotfiles_banner(repo_root: &Path, home_real: &Path, branch: &str) {
    if repo_root != home_real {
        return;
    }
    eprintln!("── dotfiles worktree — not your live $HOME ──");
    eprintln!("  Nothing here is sourced by any running shell.");
    eprintln!("  Verify:  wt verify {branch}");
    eprintln!("  Startup semantics (.zshenv/.zshrc, .config/zsh/functions) still need a $HOME branch switch.");
}

fn home_repo_guard(branch: &str) {
    eprintln!("wt: worktrees for the repo at $HOME need an explicit opt-in");
    eprintln!("  Interactive shell startup (.zshenv/.zshrc and the functions");
    eprintln!("  autoloaded from .config/zsh/functions) is only exercised from");
    eprintln!("  the real $HOME, so startup changes still need a branch switch.");
    eprintln!("  Everything the harness covers is verifiable in a worktree:");
    eprintln!("    wt switch {branch} --allow-home   create/enter");
    eprintln!("    wt verify {branch}                verify");
}

fn write_cd_file(cd_file: Option<&Path>, dest: &Path) {
    let Some(path) = cd_file else { return };
    if let Err(e) = fs::write(path, dest.as_os_str().as_encoded_bytes()) {
        eprintln!("wt: could not write --cd-file {}: {e}", path.display());
    }
}

fn apply_overlay_for(repo_root: &Path, home_real: &Path, wt: &Path) -> Result<(), i32> {
    let link_root = repo::main_worktree(repo_root)?;
    let path_key = repo::path_key(repo_root, home_real);
    overlay::apply(home_real, &path_key, &link_root, wt)
}

fn is_empty_dir(dir: &Path) -> bool {
    fs::read_dir(dir)
        .map(|mut it| it.next().is_none())
        .unwrap_or(false)
}

fn has_origin(repo_root: &Path) -> bool {
    Command::new("git")
        .arg("-C")
        .arg(repo_root)
        .args(["remote", "get-url", "origin"])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

fn fetch_prune_origin(repo_root: &Path) -> bool {
    Command::new("git")
        .arg("-C")
        .arg(repo_root)
        .args(["fetch", "--prune", "origin"])
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

fn show_ref(repo_root: &Path, ref_name: &str) -> bool {
    Command::new("git")
        .arg("-C")
        .arg(repo_root)
        .args(["show-ref", "--quiet", ref_name])
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

fn worktree_add(repo_root: &Path, args: &[&str]) -> Result<(), i32> {
    let status = Command::new("git")
        .arg("-C")
        .arg(repo_root)
        .arg("worktree")
        .arg("add")
        .args(args)
        .status();
    match status {
        Ok(s) if s.success() => Ok(()),
        Ok(s) => Err(s.code().unwrap_or(1)),
        Err(_) => Err(1),
    }
}

/// Shared switch/create sequence, mirroring `wt.sh:163-223`. `create_only`
/// refuses (exit 4) instead of reusing an already-registered worktree.
fn do_switch_or_create(
    create_only: bool,
    branch: &str,
    repo_root: &Path,
    home_real: &Path,
    allow_home: bool,
) -> Result<PathBuf, i32> {
    repo::worktree_prune(repo_root);

    if let Some(found) = repo::find_registered(repo_root, branch)? {
        if create_only {
            eprintln!("wt: {branch} is already registered at {}", found.display());
            return Err(4);
        }
        apply_overlay_for(repo_root, home_real, &found)?;
        return Ok(found);
    }

    // Home-repo guard applies to creation only — an already-registered
    // dotfiles worktree resolves above without --allow-home.
    if repo_root == home_real && !allow_home {
        home_repo_guard(branch);
        return Err(4);
    }

    let wt_path = repo::wt_path(repo_root, home_real, branch);

    if wt_path.exists() {
        if wt_path.is_dir() && is_empty_dir(&wt_path) {
            fs::remove_dir(&wt_path).map_err(|e| {
                eprintln!("wt: could not remove empty {}: {e}", wt_path.display());
                4
            })?;
        } else {
            eprintln!("wt: {} exists and is not a registered worktree", wt_path.display());
            return Err(4);
        }
    }

    if has_origin(repo_root) && !fetch_prune_origin(repo_root) {
        eprintln!("wt: git fetch --prune origin failed");
        return Err(4);
    }

    let wt_path_str = wt_path.to_string_lossy().into_owned();
    let heads_ref = format!("refs/heads/{branch}");
    let remote_ref = format!("refs/remotes/origin/{branch}");
    let origin_ref = format!("origin/{branch}");

    if show_ref(repo_root, &heads_ref) {
        worktree_add(repo_root, &["--quiet", &wt_path_str, branch])?;
    } else if show_ref(repo_root, &remote_ref) {
        worktree_add(
            repo_root,
            &["--quiet", "--track", "-b", branch, &wt_path_str, &origin_ref],
        )?;
    } else {
        worktree_add(repo_root, &["--quiet", "-b", branch, &wt_path_str])?;
    }

    apply_overlay_for(repo_root, home_real, &wt_path)?;
    Ok(wt_path)
}

fn cmd_path(args: &Args, home_real: &Path) -> Result<(), i32> {
    let branch = args.branch.as_ref().unwrap();
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    let wt_path = repo::wt_path(&repo_root, home_real, branch);
    println!("{}", wt_path.display());
    Ok(())
}

fn cmd_resolve(args: &Args, home_real: &Path) -> Result<(), i32> {
    let branch = args.branch.as_ref().unwrap();
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    repo::worktree_prune(&repo_root);
    let found = repo::find_registered(&repo_root, branch)?;
    match found {
        Some(path) => {
            println!("{}", path.display());
            Ok(())
        }
        None => {
            eprintln!("wt: no worktree registered for branch {branch}");
            Err(3)
        }
    }
}

fn cmd_switch(args: &Args, home_real: &Path) -> Result<(), i32> {
    let branch = args.branch.as_ref().unwrap();
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    let wt_path = do_switch_or_create(false, branch, &repo_root, home_real, args.allow_home)?;
    dotfiles_banner(&repo_root, home_real, branch);
    write_cd_file(args.cd_file.as_deref(), &wt_path);
    println!("{}", wt_path.display());
    Ok(())
}

fn cmd_create(args: &Args, home_real: &Path) -> Result<(), i32> {
    let branch = args.branch.as_ref().unwrap();
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    let wt_path = do_switch_or_create(true, branch, &repo_root, home_real, args.allow_home)?;
    println!("{}", wt_path.display());
    Ok(())
}

fn cmd_remove(args: &Args, home_real: &Path) -> Result<(), i32> {
    let branch = args.branch.as_ref().unwrap();
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    repo::worktree_prune(&repo_root);

    let found = repo::find_registered(&repo_root, branch)?;
    let Some(found) = found else {
        eprintln!("wt: no worktree registered for branch {branch}");
        return Err(3);
    };

    let cwd = env::current_dir().unwrap_or_default();
    let cwd_real = cwd.canonicalize().unwrap_or(cwd);
    if cwd_real == found || cwd_real.starts_with(&found) {
        eprintln!(
            "wt: refusing to remove {}: current directory is inside it",
            found.display()
        );
        return Err(4);
    }

    if found == repo_root {
        eprintln!("wt: refusing to remove the main worktree");
        return Err(4);
    }

    let mut cmd = Command::new("git");
    cmd.arg("-C").arg(&repo_root).arg("worktree").arg("remove");
    if args.force {
        cmd.arg("--force");
    }
    cmd.arg(&found);
    let status = cmd.status();
    match status {
        Ok(s) if s.success() => {}
        _ => return Err(4),
    }

    repo::worktree_prune(&repo_root);
    eprintln!("git -C {} branch -d {branch}", repo_root.display());
    Ok(())
}

fn cmd_list(args: &Args, home_real: &Path) -> Result<(), i32> {
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    for line in repo::list_lines(&repo_root)? {
        println!("{line}");
    }
    Ok(())
}

fn cmd_verify(args: &Args, home_real: &Path) -> Result<(), i32> {
    let branch = args.branch.as_ref().unwrap();
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    repo::worktree_prune(&repo_root);
    let found = repo::find_registered(&repo_root, branch)?;
    let Some(found) = found else {
        eprintln!("wt: no worktree registered for branch {branch}");
        return Err(3);
    };

    ancestor_warn(home_real, &found);

    let status = Command::new("just")
        .arg("check")
        .current_dir(&found)
        .env("HOME", &found)
        .env("MISE_DATA_DIR", home_real.join(".local").join("share").join("mise"))
        .env("GIT_CONFIG_COUNT", "1")
        .env("GIT_CONFIG_KEY_0", "commit.gpgsign")
        .env("GIT_CONFIG_VALUE_0", "false")
        .status();

    match status {
        Ok(s) if s.success() => Ok(()),
        Ok(s) => Err(s.code().unwrap_or(1)),
        Err(_) => Err(1),
    }
}

fn cmd_shell(args: &Args, home_real: &Path) -> Result<(), i32> {
    let branch = args.branch.as_ref().unwrap();
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    repo::worktree_prune(&repo_root);
    let found = repo::find_registered(&repo_root, branch)?;
    let Some(found) = found else {
        eprintln!("wt: no worktree registered for branch {branch}");
        return Err(3);
    };

    dotfiles_banner(&repo_root, home_real, branch);
    ancestor_warn(home_real, &found);

    let term = env::var("TERM")
        .ok()
        .filter(|t| !t.is_empty())
        .unwrap_or_else(|| "xterm-256color".to_string());
    let path = format!(
        "/usr/bin:/bin:/usr/sbin:/sbin:{}/.local/bin:{}/.local/share/mise/shims",
        home_real.display(),
        home_real.display()
    );

    let err = Command::new("zsh")
        .arg("-i")
        .current_dir(&found)
        .env_clear()
        .env("HOME", &found)
        .env("TERM", term)
        .env("PATH", path)
        .env("MISE_DATA_DIR", home_real.join(".local").join("share").join("mise"))
        .env("GIT_CONFIG_COUNT", "1")
        .env("GIT_CONFIG_KEY_0", "commit.gpgsign")
        .env("GIT_CONFIG_VALUE_0", "false")
        .env("WT_SHELL_CHECKOUT", &found)
        .exec();

    eprintln!("wt: exec zsh failed: {err}");
    Err(1)
}

fn cmd_overlay(args: &Args, home_real: &Path) -> Result<(), i32> {
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;

    let wt = if let Some(branch) = &args.branch {
        repo::worktree_prune(&repo_root);
        let found = repo::find_registered(&repo_root, branch)?;
        match found {
            Some(path) => path,
            None => {
                eprintln!("wt: no worktree registered for branch {branch}");
                return Err(3);
            }
        }
    } else {
        // No branch: target the worktree containing cwd — --show-toplevel
        // is correct here, the opposite of what repo_root needs.
        let output = Command::new("git")
            .args(["rev-parse", "--show-toplevel"])
            .output()
            .map_err(|_| 4)?;
        if !output.status.success() {
            eprintln!("wt: not inside a git worktree");
            return Err(4);
        }
        PathBuf::from(String::from_utf8_lossy(&output.stdout).trim())
    };

    apply_overlay_for(&repo_root, home_real, &wt)
}

fn which(bin: &str) -> Option<PathBuf> {
    let path = env::var_os("PATH")?;
    for dir in env::split_paths(&path) {
        let candidate = dir.join(bin);
        if candidate.is_file() {
            return Some(candidate);
        }
    }
    None
}

fn cmd_picker(args: &Args, home_real: &Path) -> Result<(), i32> {
    let repo_root = repo::repo_root(args.allow_home, args.repo.as_deref(), home_real)?;
    repo::worktree_prune(&repo_root);

    if which("fzf").is_none() {
        eprintln!("wt: fzf not found; use `wt list`");
        return Err(2);
    }

    let listing = Command::new("git")
        .arg("-C")
        .arg(&repo_root)
        .args(["worktree", "list"])
        .output()
        .map_err(|_| 1)?;
    if !listing.status.success() {
        return Err(1);
    }

    let mut child = Command::new("fzf")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
        .map_err(|_| 1)?;

    {
        use std::io::Write;
        let stdin = child.stdin.take().unwrap();
        let mut stdin = stdin;
        let _ = stdin.write_all(&listing.stdout);
    }

    let output = child.wait_with_output().map_err(|_| 1)?;
    let selection = String::from_utf8_lossy(&output.stdout);
    let selected_path = selection.split_whitespace().next();

    let Some(field) = selected_path else {
        return Ok(());
    };

    let wt = PathBuf::from(field);
    let branch = wt.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
    dotfiles_banner(&repo_root, home_real, &branch);
    apply_overlay_for(&repo_root, home_real, &wt)?;
    write_cd_file(args.cd_file.as_deref(), &wt);
    println!("{}", wt.display());
    Ok(())
}

pub fn dispatch(args: &Args) -> Result<(), i32> {
    let home_real = repo::home_real();
    match args.action.as_str() {
        "path" => cmd_path(args, &home_real),
        "resolve" => cmd_resolve(args, &home_real),
        "switch" => cmd_switch(args, &home_real),
        "create" => cmd_create(args, &home_real),
        "remove" => cmd_remove(args, &home_real),
        "list" => cmd_list(args, &home_real),
        "verify" => cmd_verify(args, &home_real),
        "shell" => cmd_shell(args, &home_real),
        "overlay" => cmd_overlay(args, &home_real),
        "picker" => cmd_picker(args, &home_real),
        other => {
            eprintln!("wt: unknown action: {other}");
            Err(2)
        }
    }
}
