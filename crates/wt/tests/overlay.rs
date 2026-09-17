//! Overlay manifest tests, porting `PLAN.md` step 7 cases 15-20.

mod common;

use common::*;
use std::fs;

fn output_to_string(bytes: &[u8]) -> String {
    String::from_utf8_lossy(bytes).trim().to_string()
}

fn overlay_dir(f: &common::Fixture) -> std::path::PathBuf {
    let dir = f.root.join("overlay-manifests");
    fs::create_dir_all(&dir).unwrap();
    dir
}

#[test]
fn create_applies_the_manifest() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    fs::write(f.fake_home.join(".env"), "SECRET=1\n").unwrap();

    let manifests = overlay_dir(&f);
    fs::write(manifests.join("dotfiles"), ".env\n").unwrap();

    let branch = "with-overlay";
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_OVERLAY_DIR", &manifests)
        .args(["switch", branch, "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));

    let wt = f.fake_home.join(".worktrees/dotfiles").join(branch);
    let link_target = fs::read_link(wt.join(".env")).unwrap();
    assert_eq!(link_target, f.fake_home.join(".env"));
    assert_eq!(fs::read_to_string(wt.join(".env")).unwrap(), "SECRET=1\n");
}

#[test]
fn switch_onto_already_registered_worktree_applies_manifest() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    fs::write(f.fake_home.join(".env"), "SECRET=1\n").unwrap();

    let manifests = overlay_dir(&f);
    fs::write(manifests.join("dotfiles"), ".env\n").unwrap();

    let branch = "resolve-overlay";
    // Create without the overlay manifest present.
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .args(["switch", branch, "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let wt = f.fake_home.join(".worktrees/dotfiles").join(branch);
    assert!(!wt.join(".env").exists());

    // Switching onto the already-registered worktree applies it.
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_OVERLAY_DIR", &manifests)
        .args(["switch", branch, "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    assert!(fs::symlink_metadata(wt.join(".env")).unwrap().file_type().is_symlink());
}

#[test]
fn overlay_rerun_is_idempotent() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    fs::write(f.fake_home.join(".env"), "SECRET=1\n").unwrap();

    let manifests = overlay_dir(&f);
    fs::write(manifests.join("dotfiles"), ".env\n").unwrap();

    let branch = "idempotent";
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_OVERLAY_DIR", &manifests)
        .args(["switch", branch, "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_OVERLAY_DIR", &manifests)
        .args(["overlay", branch, "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    assert!(output_to_string(&out.stderr).contains("already symlinked"));
}

#[test]
fn overlay_exits_4_when_destination_is_not_a_symlink() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    fs::write(f.fake_home.join(".env"), "SECRET=1\n").unwrap();

    let manifests = overlay_dir(&f);
    fs::write(manifests.join("dotfiles"), ".env\n").unwrap();

    let branch = "blocked";
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .args(["switch", branch, "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    let wt = f.fake_home.join(".worktrees/dotfiles").join(branch);
    fs::write(wt.join(".env"), "real-content\n").unwrap();

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_OVERLAY_DIR", &manifests)
        .args(["overlay", branch, "--allow-home"])
        .output()
        .unwrap();
    assert_eq!(out.status.code(), Some(4));
    assert_eq!(fs::read_to_string(wt.join(".env")).unwrap(), "real-content\n");
}

#[test]
fn overlay_skips_missing_source_and_links_remaining_entries() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    fs::write(f.fake_home.join(".env"), "SECRET=1\n").unwrap();
    // .missing is intentionally not created.

    let manifests = overlay_dir(&f);
    fs::write(manifests.join("dotfiles"), ".missing\n.env\n").unwrap();

    let branch = "partial";
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_OVERLAY_DIR", &manifests)
        .args(["switch", branch, "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    assert!(output_to_string(&out.stderr).contains(".missing not found"));

    let wt = f.fake_home.join(".worktrees/dotfiles").join(branch);
    assert!(fs::symlink_metadata(wt.join(".env")).unwrap().file_type().is_symlink());
    assert!(!wt.join(".missing").exists());
}

#[test]
fn overlay_targeting_main_worktree_exits_0_and_links_nothing() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    fs::write(f.fake_home.join(".env"), "SECRET=1\n").unwrap();

    let manifests = overlay_dir(&f);
    fs::write(manifests.join("dotfiles"), ".env\n").unwrap();

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_OVERLAY_DIR", &manifests)
        .args(["overlay", "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", output_to_string(&out.stderr));
    assert!(output_to_string(&out.stderr).contains("nothing to link in the main worktree"));
    // .env in $HOME is real content, not touched by the guard.
    assert!(!fs::symlink_metadata(f.fake_home.join(".env")).unwrap().file_type().is_symlink());

}
