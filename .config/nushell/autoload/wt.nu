# wt - Navigate to or create git worktrees
#   no args: fzf-select existing worktree
#   <branch>: navigate to existing worktree for branch, or create one
def --env wt [branch?: string] {
    if $branch == null {
        let result = (^git worktree list | ^fzf | complete)
        if $result.exit_code != 0 {
            return
        }
        let dir = ($result.stdout | str trim | split row -r '\s+' | first)
        if ($dir | is-not-empty) {
            cd $dir
        }
        return
    }

    # Check if branch already has a worktree
    let existing = (
        ^git worktree list --porcelain
        | lines
        | split list ""
        | where {|group| $"branch refs/heads/($branch)" in $group }
        | each {|group| $group | first | str replace "worktree " "" }
    )

    if ($existing | is-not-empty) {
        cd ($existing | first)
        return
    }

    # Dotfiles repo guard
    # Use git-common-dir to resolve the main repo root, not a worktree's toplevel
    let repo_root = (
        ^git rev-parse --path-format=absolute --git-common-dir
        | str trim
        | str replace -r '/\.git$' ''
    )
    if $repo_root == $nu.home-dir {
        error make --unspanned { msg: "dotfiles repo must not use worktrees" }
    }

    # Build worktree path: ~/.worktrees/<path-key>/<branch>
    let path_key = (
        $repo_root
        | str replace $"($nu.home-dir)/" ""
        | str replace --all "/" "-"
    )
    let wt_path = $"($nu.home-dir)/.worktrees/($path_key)/($branch)"

    if ($wt_path | path exists) {
        print $"Worktree directory already exists at ($wt_path) — reusing it"
        cd $wt_path
        return
    }

    # Refresh origin so a branch pushed after the last fetch is discoverable.
    if (^git remote get-url origin | complete).exit_code == 0 {
        let fetch_result = (^git fetch --prune origin | complete)
        if $fetch_result.exit_code != 0 {
            error make --unspanned { msg: $fetch_result.stderr }
        }
    }

    if (^git show-ref --quiet $"refs/heads/($branch)" | complete).exit_code == 0 {
        ^git worktree add $wt_path $branch
    } else if (^git show-ref --quiet $"refs/remotes/origin/($branch)" | complete).exit_code == 0 {
        ^git worktree add --track -b $branch $wt_path $"origin/($branch)"
    } else {
        ^git worktree add -b $branch $wt_path
    }
    cd $wt_path
}
