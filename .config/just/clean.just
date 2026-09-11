# clean — cache, build output, and dependency-tree cleanup

# Repo-owned source roots scanned by clean-build. The vendored
# .claude/skills/gstack tree is deliberately absent: `just build` does not
# rebuild its dist/ binaries, so purging them would leave no way back.

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

# Directories containing tracked files are kept, so this can never delete
# checked-in work. .claude/skills/gstack is out of scope via
# build_artifact_roots: `just build` does not rebuild its dist/ binaries.
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
