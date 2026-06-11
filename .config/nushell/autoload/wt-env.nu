# wt-env - Symlink env files from main worktree into current worktree
def wt-env [...files: string] {
    let files = if ($files | is-empty) { [".env"] } else { $files }

    let result = (^git worktree list --porcelain | complete)
    if $result.exit_code != 0 {
        error make --unspanned { msg: "not in a git repository" }
    }
    let main_wt = (
        $result.stdout
        | lines
        | where { $in starts-with "worktree " }
        | first
        | str replace "worktree " ""
    )

    let current_wt = (^git rev-parse --show-toplevel | str trim)

    if $current_wt == $main_wt {
        error make --unspanned { msg: "already in the main worktree" }
    }

    for file in $files {
        let src = $"($main_wt)/($file)"
        let dst = $"($current_wt)/($file)"
        if not ($src | path exists) {
            print -e $"skip: ($file) not found in main worktree"
            continue
        }
        if ($dst | path type) == "symlink" {
            print $"skip: ($file) already symlinked"
            continue
        }
        if ($dst | path exists) {
            print -e $"skip: ($file) already exists \(not a symlink)"
            continue
        }
        ^ln -s $src $dst
        print $"linked: ($file) → ($src)"
    }
}
