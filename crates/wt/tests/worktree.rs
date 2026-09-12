//! Worktree resolution and lifecycle tests, porting `tests/wt.bats`'s
//! non-overlay cases (`PLAN.md` step 7, cases 1-14).

mod common;

use common::*;
use std::fs;
use std::path::Path;

fn output_to_string(bytes: &[u8]) -> String {
    String::from_utf8_lossy(bytes).trim().to_string()
}

#[test]
fn switch_fetches_and_tracks_a_newly_available_remote_branch() {
    let f = fixture();
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.clone)
        .args(["switch", &f.branch])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));

    let worktree = find_worktree(&f.clone, &f.branch).expect("registered worktree");
    let head = std::process::Command::new("git")
        .arg("-C")
        .arg(&worktree)
        .args(["rev-parse", "HEAD"])
        .output()
        .unwrap();
    assert_eq!(output_to_string(&head.stdout), f.remote_head);

    let upstream = std::process::Command::new("git")
        .arg("-C")
        .arg(&worktree)
        .args(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"])
        .output()
        .unwrap();
    assert_eq!(output_to_string(&upstream.stdout), format!("origin/{}", f.branch));
}

#[test]
fn switch_prunes_stale_metadata_before_creating() {
    let f = fixture();
    std::process::Command::new("git")
        .arg("-C")
        .arg(&f.clone)
        .args(["fetch", "-q", "origin", &f.branch])
        .status()
        .unwrap();
    let stale = f.root.join("stale");
    std::process::Command::new("git")
        .arg("-C")
        .arg(&f.clone)
        .args([
            "worktree",
            "add",
            "-q",
            "-b",
            &f.branch,
            stale.to_str().unwrap(),
            &format!("origin/{}", f.branch),
        ])
        .status()
        .unwrap();
    fs::remove_dir_all(&stale).unwrap();

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.clone)
        .args(["switch", &f.branch])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));

    let worktree = find_worktree(&f.clone, &f.branch).expect("registered worktree");
    let head = std::process::Command::new("git")
        .arg("-C")
        .arg(&worktree)
        .args(["rev-parse", "HEAD"])
        .output()
        .unwrap();
    assert_eq!(output_to_string(&head.stdout), f.remote_head);
}

#[test]
fn picker_prunes_stale_metadata_before_listing() {
    let f = fixture();
    std::process::Command::new("git")
        .arg("-C")
        .arg(&f.clone)
        .args(["fetch", "-q", "origin", &f.branch])
        .status()
        .unwrap();
    let stale = f.root.join("stale");
    std::process::Command::new("git")
        .arg("-C")
        .arg(&f.clone)
        .args([
            "worktree",
            "add",
            "-q",
            "-b",
            &f.branch,
            stale.to_str().unwrap(),
            &format!("origin/{}", f.branch),
        ])
        .status()
        .unwrap();
    fs::remove_dir_all(&stale).unwrap();

    let fake_bin = f.root.join("bin");
    fs::create_dir_all(&fake_bin).unwrap();
    let fzf_stub = fake_bin.join("fzf");
    fs::write(&fzf_stub, "#!/bin/sh\nawk 'END { print }'\n").unwrap();
    let mut perms = fs::metadata(&fzf_stub).unwrap().permissions();
    std::os::unix::fs::PermissionsExt::set_mode(&mut perms, 0o755);
    fs::set_permissions(&fzf_stub, perms).unwrap();

    let path = format!("{}:{}", fake_bin.display(), std::env::var("PATH").unwrap());
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.clone)
        .env("PATH", path)
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
}

#[test]
fn switch_refuses_inside_home_repo_without_allow_home() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .args(["switch", "dotfiles-branch"])
        .output()
        .unwrap();
    assert_eq!(out.status.code(), Some(4));
    assert!(output_to_string(&out.stderr).contains("--allow-home"));
}

#[test]
fn switch_allow_home_registers_worktree() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .args(["switch", "dotfiles-branch", "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));

    let listing = worktree_list_porcelain(&f.fake_home);
    let expected = format!(
        "worktree {}",
        f.fake_home.join(".worktrees/dotfiles/dotfiles-branch").display()
    );
    assert!(listing.contains(&expected), "{listing}");
}

#[test]
fn allow_home_exits_4_when_home_is_not_a_git_repo() {
    let f = fixture();
    let not_a_repo = f.root.join("not-a-repo-home");
    fs::create_dir_all(&not_a_repo).unwrap();

    let out = wt_cmd(&not_a_repo)
        .current_dir(&not_a_repo)
        .args(["switch", "dotfiles-branch", "--allow-home"])
        .output()
        .unwrap();
    assert_eq!(out.status.code(), Some(4));
    assert!(output_to_string(&out.stderr).contains("$HOME is not a git repository"));
}

#[test]
fn switch_refuses_non_empty_unregistered_path() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    let wt_path = f.fake_home.join(".worktrees/dotfiles/dotfiles-branch");
    fs::create_dir_all(&wt_path).unwrap();
    fs::write(wt_path.join("marker"), "not-a-worktree\n").unwrap();

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .args(["switch", "dotfiles-branch", "--allow-home"])
        .output()
        .unwrap();
    assert_eq!(out.status.code(), Some(4));
    assert!(wt_path.join("marker").is_file());
}

#[test]
fn path_allow_home_prints_canonical_path_and_creates_nothing() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .args(["path", "dotfiles-branch", "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let expected = f.fake_home.join(".worktrees/dotfiles/dotfiles-branch");
    assert_eq!(output_to_string(&out.stdout), expected.to_string_lossy());
    assert!(!expected.exists());
}

#[test]
fn path_derives_path_key_for_repo_under_home() {
    let f = fixture();
    let proj = f.fake_home.join("dev").join("proj");
    fs::create_dir_all(&proj).unwrap();
    std::process::Command::new("git")
        .arg("init")
        .arg("-q")
        .arg(&proj)
        .status()
        .unwrap();

    let out = wt_cmd(&f.fake_home)
        .args(["path", "feature-under-home", "--repo", proj.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let expected = f.fake_home.join(".worktrees/dev-proj/feature-under-home");
    assert_eq!(output_to_string(&out.stdout), expected.to_string_lossy());
}

#[test]
fn switch_exits_4_on_mismatched_leaf() {
    let f = fixture();
    let mismatch_branch = "mismatch-branch";
    let wrongdir = f.root.join("wrongdir");
    std::process::Command::new("git")
        .arg("-C")
        .arg(&f.clone)
        .args(["worktree", "add", "-q", "-b", mismatch_branch, wrongdir.to_str().unwrap()])
        .status()
        .unwrap();

    let out = wt_cmd(&f.fake_home)
        .args(["switch", mismatch_branch, "--repo", f.clone.to_str().unwrap()])
        .output()
        .unwrap();
    assert_eq!(out.status.code(), Some(4));
}

#[test]
fn remove_deletes_clean_worktree() {
    let f = fixture();
    let branch = "remove-me";
    let out = wt_cmd(&f.fake_home)
        .args(["switch", branch, "--repo", f.clone.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let worktree = Path::new(output_to_string(&out.stdout).as_str()).to_path_buf();

    let out = wt_cmd(&f.fake_home)
        .args(["remove", branch, "--repo", f.clone.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    assert!(!worktree.exists());
    assert!(!worktree_list_porcelain(&f.clone).contains(&format!("worktree {}", worktree.display())));
}

#[test]
fn remove_refuses_when_cwd_inside_target() {
    let f = fixture();
    let branch = "inside-branch";
    let out = wt_cmd(&f.fake_home)
        .args(["switch", branch, "--repo", f.clone.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let worktree = Path::new(output_to_string(&out.stdout).as_str()).to_path_buf();

    let out = wt_cmd(&f.fake_home)
        .current_dir(&worktree)
        .args(["remove", branch, "--repo", f.clone.to_str().unwrap()])
        .output()
        .unwrap();
    assert_eq!(out.status.code(), Some(4));
    assert!(worktree.is_dir());
}

#[test]
fn list_prints_path_tab_branch_line() {
    let f = fixture();
    let branch = "list-me";
    let out = wt_cmd(&f.fake_home)
        .args(["switch", branch, "--repo", f.clone.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let worktree = output_to_string(&out.stdout);

    let out = wt_cmd(&f.fake_home)
        .args(["list", "--repo", f.clone.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let expected = format!("{worktree}\t{branch}");
    assert!(output_to_string(&out.stdout).contains(&expected));
}

#[test]
fn cd_file_receives_resolved_directory_for_switch_and_is_untouched_for_list() {
    let f = fixture();
    let cd_file = f.root.join("cd-file");
    fs::write(&cd_file, "").unwrap();

    let out = wt_cmd(&f.fake_home)
        .args([
            "switch",
            &f.branch,
            "--repo",
            f.clone.to_str().unwrap(),
            "--cd-file",
            cd_file.to_str().unwrap(),
        ])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let stdout = output_to_string(&out.stdout);
    assert_eq!(fs::read_to_string(&cd_file).unwrap(), stdout);

    fs::write(&cd_file, "unchanged").unwrap();
    let out = wt_cmd(&f.fake_home)
        .args([
            "list",
            "--repo",
            f.clone.to_str().unwrap(),
            "--cd-file",
            cd_file.to_str().unwrap(),
        ])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    assert_eq!(fs::read_to_string(&cd_file).unwrap(), "unchanged");
}
