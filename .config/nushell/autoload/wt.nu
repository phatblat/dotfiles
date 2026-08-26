# wt - Navigate to or create git worktrees
#   no args: fzf-select existing worktree
#   <branch>: navigate to existing worktree for branch, or create one
#   --dotfiles: opt in to worktrees for the dotfiles repo ($HOME), from any cwd
#   --test: like --dotfiles, then run `just check` against the worktree instead of entering it
#   --shell: like --dotfiles, then open an isolated interactive shell inside the worktree

# Warns to stderr, once per differing file, when a config file that tools
# discover by walking up from cwd differs between $wt_path and the real
# $HOME. Silent when the files match, since that is the common case.
def _wt_ancestor_warn [home_real: string, wt: string] {
    for f in [.config/mise/config.toml .editorconfig .envrc] {
        let home_f = ([$home_real $f] | path join)
        let wt_f = ([$wt $f] | path join)
        if ($home_f | path exists) and ($wt_f | path exists) {
            if (^cmp -s $home_f $wt_f | complete).exit_code != 0 {
                print --stderr $"warning: ($f) differs between this worktree and \$HOME;"
                print --stderr "         tools that search parent directories may use the $HOME copy."
            }
        }
    }
}

def --env wt [branch?: string, --dotfiles, --test, --shell] {
    if $test and $shell {
        error make --unspanned { msg: "wt: --test and --shell cannot be combined" }
    }
    let dotfiles_ok = ($dotfiles or $test or $shell)

    # Resolve the target repo: $HOME when opted in (regardless of cwd), else
    # whatever repo cwd is inside. Compared and built against the symlink-
    # resolved form of $HOME, since `git rev-parse` and `git worktree list`
    # always report resolved paths (macOS puts $TMPDIR under /var, itself a
    # symlink to /private/var, so an unresolved comparison silently never
    # matches there even though it does on an unsymlinked real $HOME).
    let home_real = ($nu.home-dir | path expand)

    let repo_root = if $dotfiles_ok {
        if (^git -C $home_real rev-parse --git-dir | complete).exit_code != 0 {
            error make --unspanned { msg: "wt: $HOME is not a git repository" }
        }
        $home_real
    } else {
        ^git rev-parse --path-format=absolute --git-common-dir
        | str trim
        | str replace -r '/\.git$' ''
    }

    # Remove administrative entries for worktrees whose directories were deleted.
    ^git -C $repo_root worktree prune

    if $branch == null and not $dotfiles_ok {
        let result = (^git -C $repo_root worktree list | ^fzf | complete)
        if $result.exit_code != 0 {
            return
        }
        let dir = ($result.stdout | str trim | split row -r '\s+' | first)
        if ($dir | is-not-empty) {
            cd $dir
        }
        return
    }

    if $branch == null {
        error make --unspanned { msg: "wt: branch name required" }
    }

    let matching_worktrees = (
        ^git -C $repo_root worktree list --porcelain
        | lines
        | split list ""
        | where {|group| $"branch refs/heads/($branch)" in $group }
        | each {|group| $group | first | str replace "worktree " "" }
    )
    mut wt_path = ""
    if ($matching_worktrees | is-not-empty) {
        $wt_path = ($matching_worktrees | first)
    }

    if ($wt_path | is-empty) {
        # No worktree registered for this branch yet — may need to create one.

        # Dotfiles repo guard
        if $repo_root == $home_real and not $dotfiles_ok {
            error make --unspanned {
                msg: (
                    "wt: dotfiles worktrees need an explicit opt-in\n"
                    + "  Interactive shell startup (.zshenv/.zshrc and the functions\n"
                    + "  autoloaded from .config/zsh/functions) is only exercised from\n"
                    + "  the real $HOME, so startup changes still need a branch switch.\n"
                    + "  Everything the harness covers is verifiable in a worktree:\n"
                    + $"    wt --dotfiles ($branch)   create/enter    wt --test ($branch)   verify"
                )
            }
        }

        # Build worktree path: ~/.worktrees/<path-key>/<branch>
        $wt_path = if $repo_root == $home_real {
            let root = ($env.DOTFILES_WT_ROOT? | default $"($home_real)/.worktrees/dotfiles")
            $"($root)/($branch)"
        } else {
            let path_key = (
                $repo_root
                | str replace $"($home_real)/" ""
                | str replace --all "/" "-"
            )
            $"($home_real)/.worktrees/($path_key)/($branch)"
        }

        let registered = (
            ^git -C $repo_root worktree list --porcelain
            | lines
            | any {|l| $l == $"worktree ($wt_path)" }
        )

        if not $registered {
            if ($wt_path | path exists) {
                let is_empty_dir = (($wt_path | path type) == "dir") and ((ls $wt_path) | is-empty)
                if $is_empty_dir {
                    rm $wt_path
                } else {
                    error make --unspanned { msg: $"wt: ($wt_path) exists and is not a registered worktree" }
                }
            }

            # Refresh origin so a branch pushed after the last fetch is discoverable.
            if (^git -C $repo_root remote get-url origin | complete).exit_code == 0 {
                let fetch_result = (^git -C $repo_root fetch --prune origin | complete)
                if $fetch_result.exit_code != 0 {
                    error make --unspanned { msg: $fetch_result.stderr }
                }
            }

            if (^git -C $repo_root show-ref --quiet $"refs/heads/($branch)" | complete).exit_code == 0 {
                ^git -C $repo_root worktree add $wt_path $branch
            } else if (^git -C $repo_root show-ref --quiet $"refs/remotes/origin/($branch)" | complete).exit_code == 0 {
                ^git -C $repo_root worktree add --track -b $branch $wt_path $"origin/($branch)"
            } else {
                ^git -C $repo_root worktree add -b $branch $wt_path
            }
        }
    }

    # From here $wt_path is set, whether pre-existing, reused, or freshly created.

    if $test {
        _wt_ancestor_warn $home_real $wt_path
        ^env HOME=$wt_path MISE_DATA_DIR=$"($home_real)/.local/share/mise" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false sh -c 'cd "$1" && just check' sh $wt_path
        return
    }

    if $repo_root == $home_real {
        print --stderr "── dotfiles worktree — not your live $HOME ──"
        print --stderr "  Nothing here is sourced by any running shell."
        print --stderr $"  Verify:  wt --test ($branch)"
        print --stderr "  Startup semantics (.zshenv/.zshrc, .config/zsh/functions) still need a $HOME branch switch."
    }

    if $shell {
        _wt_ancestor_warn $home_real $wt_path
        # A separate `sh -c` process does the cd-then-exec, so the calling
        # nu session's own cwd is never touched (only the forked-and-exec'd
        # child's cwd changes, mirroring the zsh subshell counterpart).
        let shell_path = $"/usr/bin:/bin:/usr/sbin:/sbin:($home_real)/.local/bin:($home_real)/.local/share/mise/shims"
        let mise_data_dir = $"($home_real)/.local/share/mise"
        ^sh -c 'cd "$1" && exec env -i HOME="$1" TERM="$2" PATH="$3" MISE_DATA_DIR="$4" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false WT_SHELL_CHECKOUT="$1" zsh -i' sh $wt_path ($env.TERM? | default "") $shell_path $mise_data_dir
        return
    }

    cd $wt_path
}
