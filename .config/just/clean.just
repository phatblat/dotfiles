# clean — cache, build output, and dependency-tree cleanup

# Repo-owned source roots scanned by clean-build.

build_artifact_roots := '.agents .codex .config .omp docs scripts tests'

# Directory names clean-build treats as regenerable build output

build_artifact_dirs := '.build .pytest_cache .ruff_cache __pycache__ dist target'

# Every entry here is re-downloadable. ~/.cache/huggingface is deliberately
# excluded: model weights are data, not build output, and re-fetching 183 GB
# costs hours of bandwidth.
# Removes package manager download, cache, and temp directories
[group('clean')]
[script]
clean-caches:
    set -euo pipefail
    if command -v mise >/dev/null 2>&1; then
        cache_dir="$(mise cache)"
        if [[ -d "$cache_dir" ]]; then trash "$cache_dir"; fi
        mise cache clear --yes
        mise prune --yes
    fi
    if command -v brew >/dev/null 2>&1; then
        brew cleanup
        rm -rf "$(brew --cache)"
    fi
    if command -v uv >/dev/null 2>&1; then uv cache clean; fi
    # bun >= 1.4 requires a package.json in cwd for `bun pm cache rm`;
    # run it from a throwaway package so cache-dir resolution stays bun's
    if command -v bun >/dev/null 2>&1; then
        bun_tmp="$(mktemp -d)"
        echo '{}' > "$bun_tmp/package.json"
        (cd "$bun_tmp" && bun pm cache rm)
        rm -rf "$bun_tmp"
    fi
    if command -v npm >/dev/null 2>&1; then npm cache clean --force; fi
    if command -v pnpm >/dev/null 2>&1; then pnpm store prune; fi
    if command -v go >/dev/null 2>&1; then go clean -cache -modcache -testcache -fuzzcache; fi
    if python3 -m pip --version >/dev/null 2>&1; then python3 -m pip cache purge; fi
    rm -rf "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/src" "$HOME/.cargo/git/checkouts"
    if command -v nix >/dev/null 2>&1; then nix store gc; fi

# ~/.cache subdirectories that clean-tool-caches removes (space-separated). An
# allowlist, because ~/.cache also holds data that is not a cache: the wine
# prefix, lm-studio models, huggingface weights, and tool state.

tool_cache_dirs := 'ansible-compat ansible-lint chrome-devtools-mcp gem gstreamer-1.0 packer pre-commit puppeteer solargraph starship ty update-informer-rs uv zig'

# Every entry removed here is re-downloaded or rebuilt on demand. Kept on
# purpose: ~/.gradle/gradle.properties (user config) and ~/.rustup/toolchains
# and settings.toml (clean-rust prunes toolchains).
# Removes Bazel, Gradle, Kotlin/Native, rustup download, and ~/.cache tool caches
[group('clean')]
[script]
clean-tool-caches:
    set -euo pipefail
    purge() {
        local path
        for path in "$@"; do
            if [[ -e "$path" ]]; then
                echo "removing: $path"
                chmod -R u+w "$path" 2>/dev/null || true
                rm -rf "$path"
            fi
        done
    }
    # Daemons hold files open under the directories removed below.
    if command -v bazel >/dev/null 2>&1; then bazel shutdown >/dev/null 2>&1 || true; fi
    pkill -f GradleDaemon || true
    purge "$HOME/Library/Caches/bazel" "$HOME/.konan"
    for name in caches daemon jdks kotlin-profile native notifications vcs-1 wrapper workers; do
        purge "$HOME/.gradle/$name"
    done
    purge "$HOME/.rustup/downloads" "$HOME/.rustup/tmp"
    for name in {{ tool_cache_dirs }}; do
        purge "$HOME/.cache/$name"
    done

# Directories containing tracked files are kept, so this can never delete
# checked-in work.
# Removes build output directories under repo-owned source roots
[group('clean')]
[script]
clean-build:
    set -euo pipefail
    cd {{ justfile_directory() }}
    removed=0
    for name in {{ build_artifact_dirs }}; do
        candidates=()
        if [[ -d "$name" ]]; then candidates+=("$name"); fi
        for root in {{ build_artifact_roots }}; do
            if [[ ! -d "$root" ]]; then continue; fi
            while IFS= read -r -d '' dir; do
                candidates+=("$dir")
            done < <(find "$root" -type d -name "$name" -not -path '*/node_modules/*' -print0)
        done
        for dir in "${candidates[@]}"; do
            if [[ -n "$(git ls-files -- "$dir")" ]]; then
                echo "keeping tracked: $dir"
                continue
            fi
            echo "removing: $dir"
            rm -rf "$dir"
            removed=$((removed + 1))
        done
    done
    echo "clean-build removed $removed directories"

# Removes installed dependency trees and throwaway virtualenvs; `just deps`
# restores node_modules and `uv run`/`uv sync` recreates .venv.
# Removes installed dependency trees and temporary virtual environments
[group('clean')]
[script]
clean-deps:
    set -euo pipefail
    cd {{ justfile_directory() }}
    for dir in {{ bun_manifest_dirs }}; do
        if [[ -d "$dir/node_modules" ]]; then
            echo "removing: $dir/node_modules"
            rm -rf "$dir/node_modules"
        fi
    done
    for root in . {{ build_artifact_roots }}; do
        if [[ -d "$root/.venv" ]]; then
            echo "removing: $root/.venv"
            rm -rf "$root/.venv"
        fi
    done

# A worktree under ~/.worktrees is removable when it is not on its repo's
# default branch, has no uncommitted, untracked, or gitignored files (removal
# deletes ignored data such as .env, which git cannot recover), has had no commit or
# checkout for `days` days (a brand-new branch is trivially an ancestor of the
# default branch), and its branch is either an ancestor of the default branch
# or has an upstream that is gone (deleted on the remote after a squash or
# rebase merge). The branch itself is kept; use git-cleanup for branches.
# `just clean-worktrees list` only reports.
# Removes merged, idle, clean git worktrees under ~/.worktrees
[group('clean')]
[script]
clean-worktrees mode="remove" days="7":
    set -euo pipefail
    if [[ "{{ mode }}" != "remove" && "{{ mode }}" != "list" ]]; then
        echo "mode must be remove or list" >&2
        exit 2
    fi
    now="$(date +%s)"
    removed=0
    kept=0
    while IFS= read -r gitfile; do
        dir="${gitfile%/.git}"
        if ! gitdir="$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null)"; then
            echo "skipping (broken gitfile, run git worktree prune in its repo): $dir"
            continue
        fi
        branch="$(git -C "$dir" branch --show-current)"
        main="$(git -C "$dir" worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')"
        if [[ -z "$branch" || "$dir" == "$main" ]]; then continue; fi
        git -C "$main" fetch --prune --quiet origin 2>/dev/null || true
        default="$(git -C "$main" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)"
        if [[ "$branch" == "${default#origin/}" ]]; then
            echo "keeping (default branch): $dir [$branch]"
            kept=$((kept + 1))
            continue
        fi
        if [[ -n "$(git --no-optional-locks -C "$dir" status --porcelain --ignored)" ]]; then
            echo "keeping (uncommitted, untracked, or gitignored files): $dir [$branch]"
            kept=$((kept + 1))
            continue
        fi
        last="$(stat -f %m "$gitdir/logs/HEAD" 2>/dev/null || echo "$now")"
        if (( now - last < {{ days }} * 86400 )); then
            echo "keeping (active within {{ days }} days): $dir [$branch]"
            kept=$((kept + 1))
            continue
        fi
        reason=""
        if git -C "$main" merge-base --is-ancestor "$branch" "$default" 2>/dev/null; then
            reason="merged into $default"
        elif [[ "$(git -C "$main" for-each-ref --format='%(upstream:track)' "refs/heads/$branch")" == "[gone]" ]]; then
            reason="upstream gone"
        fi
        if [[ -z "$reason" ]]; then
            echo "keeping (unmerged): $dir [$branch]"
            kept=$((kept + 1))
            continue
        fi
        echo "removing ($reason): $dir [$branch]"
        if [[ "{{ mode }}" == "remove" ]]; then
            if ! wt remove "$branch" --repo "$main"; then
                echo "failed: wt remove $branch ($dir)" >&2
                kept=$((kept + 1))
                continue
            fi
        fi
        removed=$((removed + 1))
    done < <(find "$HOME/.worktrees" -maxdepth 3 -type f -name .git)
    echo "clean-worktrees: $removed removable, $kept kept"

# Runs kondo over every git repo under ~/dev and ~/.worktrees, deleting
# build artifacts older than 1 day without confirmation. Repos are
# discovered at any depth by locating .git directories and .git worktree
# files; artifact trees are skipped during traversal so nested checkouts
# (e.g. SPM .build/checkouts) are not double-counted.
[group('clean')]
[script]
clean-dev:
    set -euo pipefail
    if ! command -v kondo >/dev/null 2>&1; then
        echo "kondo is not installed (brew install kondo)" >&2
        exit 1
    fi
    repo_list="$(mktemp)"
    trap 'rm -f "$repo_list"' EXIT
    find "$HOME/dev" "$HOME/.worktrees" \
        \( -type d \( -name node_modules -o -name .venv -o -name target \
            -o -name .build -o -name dist -o -name .terraform \) -prune \) \
        -o \( -type d -name .git -print -prune \) \
        -o \( -type f -name .git -print \) \
        | sed 's|/\.git$||' \
        | sort -u > "$repo_list"
    if [[ ! -s "$repo_list" ]]; then
        echo "no git repos found under ~/dev or ~/.worktrees"
        exit 0
    fi
    repo_count="$(wc -l < "$repo_list" | tr -d ' ')"
    echo "kondo: scanning $repo_count repos under ~/dev and ~/.worktrees"
    repos=()
    while IFS= read -r repo; do
        repos+=("$repo")
    done < "$repo_list"
    kondo --all --older 1d "${repos[@]}"
