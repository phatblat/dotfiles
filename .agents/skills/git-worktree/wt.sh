#!/usr/bin/env bash
# wt.sh — headless git worktree resolver for agent sessions
# Mirrors ~/.config/nushell/autoload/wt.nu and ~/.config/zsh/functions/wt,
# minus their interactive-shell/fzf-picker surface, since an agent cannot
# use either.
#
# Usage: wt.sh <action> [<branch>] [--dotfiles] [--repo <dir>] [--force]
#   path <branch>      print the path that *would* be used; mutates nothing
#   resolve <branch>   print the registered worktree path, or exit 3
#   switch <branch>    resolve, else create; print the path
#   create <branch>    create only; exit 4 if already registered
#   remove <branch>    git worktree remove + prune; never touches the branch
#   list               one <path>\t<branch> line per worktree
#   verify <branch>    dotfiles only: just check with HOME remapped
#
# stdout carries only machine output. All human/diagnostic text goes to
# stderr. Exit codes: 0 ok, 2 usage error, 3 not found, 4 refused. git
# failures in switch/create/verify may leak raw exit codes (1, 128).
set -euo pipefail

usage() {
    echo "usage: wt.sh <action> [<branch>] [--dotfiles] [--repo <dir>] [--force]" >&2
    exit 2
}

[ $# -ge 1 ] || usage
action=$1
shift

branch=""
dotfiles=false
force=false
repo_dir=""

while [ $# -gt 0 ]; do
    case "$1" in
    --dotfiles)
        dotfiles=true
        shift
        ;;
    --force)
        force=true
        shift
        ;;
    --repo)
        [ $# -ge 2 ] || usage
        repo_dir=$2
        shift 2
        ;;
    --*)
        echo "wt.sh: unknown flag: $1" >&2
        exit 2
        ;;
    *)
        if [ -z "$branch" ]; then
            branch=$1
            shift
        else
            usage
        fi
        ;;
    esac
done

require_branch() {
    if [ -z "$branch" ]; then
        echo "wt.sh: $action requires a branch argument" >&2
        exit 2
    fi
}

# git always reports resolved paths (git rev-parse, git worktree list).
home_real=$(cd "$HOME" && pwd -P)
repo_root=""

derive_repo_root() {
    if [ "$dotfiles" = true ]; then
        if ! git -C "$home_real" rev-parse --git-dir > /dev/null 2>&1; then
            echo "wt.sh: \$HOME is not a git repository" >&2
            exit 4
        fi
        repo_root=$home_real
    else
        if ! repo_root=$(git -C "${repo_dir:-$PWD}" rev-parse --path-format=absolute --git-common-dir 2> /dev/null); then
            echo "wt.sh: not inside a git repository (${repo_dir:-$PWD})" >&2
            exit 4
        fi
        repo_root=${repo_root%/.git}
    fi
}

# Prints the canonical worktree path for repo_root/branch. Does not touch
# the filesystem — this is also the "path" action's whole implementation.
derive_wt_path() {
    local rr=$1 br=$2
    if [ "$rr" = "$home_real" ]; then
        local root=${DOTFILES_WT_ROOT:-$home_real/.worktrees/dotfiles}
        printf '%s/%s\n' "$root" "$br"
    else
        local path_key=${rr#"$home_real"/}
        path_key=${path_key//\//-}
        printf '%s/.worktrees/%s/%s\n' "$home_real" "$path_key" "$br"
    fi
}

# Finds a worktree already registered for refs/heads/<branch> under
# repo_root. Prints the path (empty if none). Exits 4 if a registered
# worktree's leaf does not match the branch — a mismatch is a defect to
# surface, never to silently adopt.
find_registered() {
    local rr=$1 br=$2 found
    found=$(git -C "$rr" worktree list --porcelain | awk -v b="refs/heads/$br" '
        /^worktree /{ wt=substr($0, 10) }
        /^branch /{ if ($2 == b) print wt }
    ')
    if [ -n "$found" ] && [ "$found" != "$rr" ]; then
        case "$found" in
        */"$br") ;;
        *)
            echo "wt.sh: registered worktree for $br has a mismatched directory" >&2
            echo "  registered: $found" >&2
            echo "  expected to end in: /$br" >&2
            exit 4
            ;;
        esac
    fi
    printf '%s' "$found"
}

wt_ancestor_warn() {
    local home=$1 wt=$2 f
    for f in .config/mise/config.toml .editorconfig .envrc; do
        if [ -f "$home/$f" ] && [ -f "$wt/$f" ]; then
            if ! cmp -s "$home/$f" "$wt/$f"; then
                echo "warning: $f differs between this worktree and \$HOME;" >&2
                echo "         tools that search parent directories may use the \$HOME copy." >&2
            fi
        fi
    done
}

cmd_path() {
    require_branch
    derive_repo_root
    derive_wt_path "$repo_root" "$branch"
}

cmd_resolve() {
    require_branch
    derive_repo_root
    git -C "$repo_root" worktree prune
    local found
    found=$(find_registered "$repo_root" "$branch")
    if [ -z "$found" ]; then
        echo "wt.sh: no worktree registered for branch $branch" >&2
        exit 3
    fi
    printf '%s\n' "$found"
}

# Shared switch/create sequence, mirroring wt.nu:49-151. create_only=true
# refuses (exit 4) instead of reusing an already-registered worktree.
do_switch_or_create() {
    local create_only=$1
    derive_repo_root
    git -C "$repo_root" worktree prune

    local found
    found=$(find_registered "$repo_root" "$branch")
    if [ -n "$found" ]; then
        if [ "$create_only" = true ]; then
            echo "wt.sh: $branch is already registered at $found" >&2
            exit 4
        fi
        printf '%s\n' "$found"
        return 0
    fi

    # Dotfiles guard applies only to creation — an already-registered
    # dotfiles worktree resolves above without --dotfiles.
    if [ "$repo_root" = "$home_real" ] && [ "$dotfiles" != true ]; then
        cat >&2 << EOF
wt.sh: dotfiles worktrees need an explicit opt-in
  Interactive shell startup (.zshenv/.zshrc and the functions
  autoloaded from .config/zsh/functions) is only exercised from
  the real \$HOME, so startup changes still need a branch switch.
  Everything the harness covers is verifiable in a worktree:
    /git:worktree switch $branch --dotfiles   create/enter
    /git:worktree verify $branch              verify
EOF
        exit 4
    fi

    local wt_path
    wt_path=$(derive_wt_path "$repo_root" "$branch")

    if [ -e "$wt_path" ]; then
        if [ -d "$wt_path" ] && [ -z "$(ls -A "$wt_path" 2> /dev/null)" ]; then
            rmdir "$wt_path"
        else
            echo "wt.sh: $wt_path exists and is not a registered worktree" >&2
            exit 4
        fi
    fi

    # Refresh origin so a branch pushed after the last fetch is discoverable.
    if git -C "$repo_root" remote get-url origin > /dev/null 2>&1; then
        if ! git -C "$repo_root" fetch --prune origin; then
            echo "wt.sh: git fetch --prune origin failed" >&2
            exit 4
        fi
    fi

    if git -C "$repo_root" show-ref --quiet "refs/heads/$branch"; then
        git -C "$repo_root" worktree add --quiet "$wt_path" "$branch"
    elif git -C "$repo_root" show-ref --quiet "refs/remotes/origin/$branch"; then
        git -C "$repo_root" worktree add --quiet --track -b "$branch" "$wt_path" "origin/$branch"
    else
        git -C "$repo_root" worktree add --quiet -b "$branch" "$wt_path"
    fi

    printf '%s\n' "$wt_path"
}

cmd_switch() {
    require_branch
    do_switch_or_create false
}

cmd_create() {
    require_branch
    do_switch_or_create true
}

cmd_remove() {
    require_branch
    derive_repo_root
    git -C "$repo_root" worktree prune

    local found
    found=$(find_registered "$repo_root" "$branch")
    if [ -z "$found" ]; then
        echo "wt.sh: no worktree registered for branch $branch" >&2
        exit 3
    fi

    local cur
    cur=$(pwd -P)
    case "$cur" in
    "$found" | "$found"/*)
        echo "wt.sh: refusing to remove $found: current directory is inside it" >&2
        exit 4
        ;;
    esac

    if [ "$found" = "$repo_root" ]; then
        echo "wt.sh: refusing to remove the main worktree" >&2
        exit 4
    fi

    if [ "$force" = true ]; then
        if ! git -C "$repo_root" worktree remove --force "$found"; then
            exit 4
        fi
    else
        if ! git -C "$repo_root" worktree remove "$found"; then
            exit 4
        fi
    fi

    git -C "$repo_root" worktree prune
    printf 'git -C %s branch -d %s\n' "$repo_root" "$branch" >&2
}

cmd_verify() {
    require_branch
    if [ -n "$repo_dir" ]; then
        echo "wt.sh: verify is dotfiles-only; omit --repo and run your own test command (e.g. just check) for other repos" >&2
        exit 2
    fi
    dotfiles=true
    derive_repo_root
    git -C "$repo_root" worktree prune

    local found
    found=$(find_registered "$repo_root" "$branch")
    if [ -z "$found" ]; then
        echo "wt.sh: no worktree registered for branch $branch" >&2
        exit 3
    fi

    wt_ancestor_warn "$home_real" "$found"
    env HOME="$found" MISE_DATA_DIR="$home_real/.local/share/mise" \
        GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false \
        sh -c 'cd "$1" && just check' sh "$found"
}

cmd_list() {
    derive_repo_root
    git -C "$repo_root" worktree list --porcelain | awk '
        /^worktree /{ wt=substr($0, 10) }
        /^branch /{ b=$2; sub("^refs/heads/", "", b); print wt"\t"b; next }
        /^detached$/{ print wt"\t(detached)" }
    '
}

case "$action" in
path) cmd_path ;;
resolve) cmd_resolve ;;
switch) cmd_switch ;;
create) cmd_create ;;
remove) cmd_remove ;;
verify) cmd_verify ;;
list) cmd_list ;;
*) usage ;;
esac
