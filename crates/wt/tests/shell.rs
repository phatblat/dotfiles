//! `wt shell` tests: the exec'd program comes from `$WT_SHELL` and runs
//! with `$HOME`/`$XDG_CONFIG_HOME` remapped into the worktree.

mod common;

use common::*;
use std::fs;

fn stderr(out: &std::process::Output) -> String {
    String::from_utf8_lossy(&out.stderr).trim().to_string()
}

fn create_dotfiles_worktree(f: &Fixture, branch: &str) -> std::path::PathBuf {
    let manifests = f.root.join("overlay-manifests");
    fs::create_dir_all(&manifests).unwrap();
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_OVERLAY_DIR", &manifests)
        .args(["create", branch, "--allow-home"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", stderr(&out));
    f.fake_home.join(".worktrees/dotfiles").join(branch)
}

#[test]
fn shell_execs_wt_shell_with_its_arguments_in_a_remapped_home() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    let wt = create_dotfiles_worktree(&f, "shell-env");

    // `sh -c '...'` can't be expressed through whitespace splitting, so the
    // probe is a script and WT_SHELL names it with a marker argument to
    // prove arguments after the program are forwarded.
    let probe = f.root.join("probe.sh");
    fs::write(&probe, "#!/bin/sh\necho \"arg=$1\"\necho \"home=$HOME\"\necho \"xdg=$XDG_CONFIG_HOME\"\necho \"pwd=$(pwd)\"\n")
        .unwrap();
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(&probe, fs::Permissions::from_mode(0o755)).unwrap();
    }

    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_SHELL", format!("{} marker", probe.display()))
        .args(["shell", "shell-env"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", stderr(&out));
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("arg=marker"), "{stdout}");
    assert!(stdout.contains(&format!("home={}", wt.display())), "{stdout}");
    assert!(stdout.contains(&format!("xdg={}", wt.join(".config").display())), "{stdout}");
    assert!(stdout.contains(&format!("pwd={}", wt.display())), "{stdout}");
}

#[test]
fn shell_falls_back_to_zsh_when_wt_shell_is_unset_or_blank() {
    let f = fixture();
    init_dotfiles_home(&f.fake_home);
    create_dotfiles_worktree(&f, "shell-default");

    // A blank WT_SHELL is "unset", not "run the empty string": the fallback
    // `zsh -i` must run. With HOME remapped, an interactive zsh sources the
    // worktree's own .zshrc, which is where the proof comes from. An
    // interactive zsh does not read commands from a non-tty stdin — it opens
    // /dev/tty instead, so the harness's null stdin never delivers EOF and
    // the shell would block on the controlling terminal forever. The .zshrc
    // therefore exits explicitly after printing its marker.
    let wt = f.fake_home.join(".worktrees/dotfiles/shell-default");
    fs::write(wt.join(".zshrc"), "echo \"zshrc-home=$HOME\"\nexit\n").unwrap();
    let out = wt_cmd(&f.fake_home)
        .current_dir(&f.fake_home)
        .env("WT_SHELL", "   ")
        .args(["shell", "shell-default"])
        .output()
        .unwrap();
    assert!(out.status.success(), "{}", stderr(&out));
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains(&format!("zshrc-home={}", wt.display())), "{stdout}");
}
