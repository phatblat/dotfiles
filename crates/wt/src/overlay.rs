//! Manifest-driven symlink farm generalising `wt-env`
//! (`.config/zsh/functions/wt-env`).

use std::env;
use std::fs;
use std::os::unix::fs::symlink;
use std::path::{Path, PathBuf};

/// `${WT_OVERLAY_DIR:-<home_real>/.config/wt/overlay}/<path-key>`, falling
/// back to `default` in the same directory, then to no manifest at all.
fn manifest_path(home_real: &Path, path_key: &str) -> Option<PathBuf> {
    let dir = env::var_os("WT_OVERLAY_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| home_real.join(".config").join("wt").join("overlay"));

    let named = dir.join(path_key);
    if named.is_file() {
        return Some(named);
    }
    let default = dir.join("default");
    if default.is_file() {
        return Some(default);
    }
    None
}

/// One worktree-relative path per line; `#` starts a comment; blank lines
/// ignored; surrounding whitespace trimmed.
fn parse_manifest(text: &str) -> Vec<String> {
    text.lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(str::to_string)
        .collect()
}

/// Applies the manifest for `path_key` from `link_root` into `wt`. `wt`
/// being the link root itself is a no-op, not an error: `switch` applies
/// the overlay on both create and resolve, and resolving the main
/// worktree must not trip the "exists and is not a symlink" guard against
/// its own real content.
pub fn apply(home_real: &Path, path_key: &str, link_root: &Path, wt: &Path) -> Result<(), i32> {
    if wt == link_root {
        eprintln!("wt: overlay: nothing to link in the main worktree");
        return Ok(());
    }

    let Some(manifest) = manifest_path(home_real, path_key) else {
        return Ok(());
    };

    let text = fs::read_to_string(&manifest).map_err(|e| {
        eprintln!("wt: could not read overlay manifest {}: {e}", manifest.display());
        4
    })?;

    for entry in parse_manifest(&text) {
        let source = link_root.join(&entry);
        let dest = wt.join(&entry);

        if !source.exists() {
            eprintln!("skip: {entry} not found in main worktree");
            continue;
        }

        match fs::symlink_metadata(&dest) {
            Ok(meta) if meta.file_type().is_symlink() => {
                eprintln!("skip: {entry} already symlinked");
                continue;
            }
            Ok(_) => {
                eprintln!("wt: {entry} exists in the worktree and is not a symlink");
                return Err(4);
            }
            Err(_) => {}
        }

        if let Some(parent) = dest.parent() {
            if let Err(e) = fs::create_dir_all(parent) {
                eprintln!("wt: could not create {}: {e}", parent.display());
                return Err(4);
            }
        }

        if let Err(e) = symlink(&source, &dest) {
            eprintln!("wt: could not symlink {}: {e}", dest.display());
            return Err(4);
        }
        eprintln!("linked: {entry} → {}", source.display());
    }

    Ok(())
}
