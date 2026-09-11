#
# justfile for ~phatblat
#
# Recipes live in one fragment per domain under .config/just/, imported below;
# each fragment's group name is its file stem. This file holds only settings,
# cross-fragment variables, and the lifecycle recipes that fan out across
# fragments. `just --list` is still the flat, grouped index of everything.
#

export PATH := env("HOME") / ".local" / "bin" + ":" + env("PATH")

set ignore-comments

set script-interpreter := ['bash', '-eu']

set unstable

# Bun dependency trees installed from tracked package.json manifests; installed by
# install-bun-deps (omp.just), purged by clean-deps (clean.just)

bun_manifest_dirs := '.omp/plugins .claude/skills/gstack'

import '.config/just/agents.just'
import '.config/just/brew.just'
import '.config/just/claude.just'
import '.config/just/clean.just'
import '.config/just/git.just'
import '.config/just/macos.just'
import '.config/just/mise.just'
import '.config/just/nix.just'
import '.config/just/omp.just'
import '.config/just/python.just'
import '.config/just/rust.just'

alias fmt := format
alias i := deps
alias up := upgrade

# Default recipe, lists available recipes
[default]
_default:
    @just --list

#
# configuration group recipes
#

# Installs tools using mise
[group('configuration')]
deps: _check-github-token install-brew install-gh-extensions install-bun-deps install-rust-deps git-filters git-hooks
    mise install

# Runs every hk fix step over all tracked files (steps live in hk.pkl)
[group('configuration')]
format:
    hk fix --all

# Common upgrades
[group('configuration')]
upgrade: upgrade-mise upgrade-mise-tools-commit update-brew upgrade-brew upgrade-uv-tools

# Purges caches, build output, dependency trees, and home directory clutter
[group('configuration')]
clean: clean-rust clean-caches clean-build clean-deps
    rm -f "$HOME/Library/Application Support/default.store"*
    rm -f $HOME/*.hprof
    rm -f $HOME/.claude.json.backup.*
    rm -f $HOME/.zcompdump.DTO-*

#
# build group recipes
#

# Every tool or artifact generated from checked-in source belongs here: add its
# build step as a dependency so a single `just build` reproduces every output.
# Rebuilds every output generated from checked-in source
[group('build')]
build: generate

# Alias for harness-generate
[group('build')]
generate: harness-generate

#
# checks group recipes
#

# Runs lint, type checks, harness parity checks, ness tests, and test
[group('checks')]
check: lint typecheck-python check-spelling harness-check agentlink-check ness-test test

# CI: lint.yml (lint job)
# Runs every hk check step over all tracked files (steps live in hk.pkl)
[group('checks')]
lint:
    hk check --all

# Checks spelling with typos
[group('checks')]
check-spelling:
    mise exec -- typos

# Runs system diagnostics using mise and homebrew
[group('checks')]
doctor:
    mise doctor
    brew doctor
    claude doctor

#
# tests group recipes
#

# CI: lint.yml (test job)
# Runs bats tests in parallel; `just test abort` stops at the first failure
[group('tests')]
[script]
test mode="parallel":
    echo "Running tests..."
    eval "$(mise activate bash)"
    [[ -d /nix/var/nix/profiles/default/bin ]] && export PATH="$PATH:/nix/var/nix/profiles/default/bin:${HOME}/.nix-profile/bin" || true
    case "{{ mode }}" in
    parallel)
        # Tests within a file share fixtures (generated docs, SIGINT timing),
        # so parallelize across files only -- within-file parallelism races.
        # Fall back to a literal count: an empty --jobs makes bats run 0 tests.
        jobs=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
        bats --print-output-on-failure --jobs "$jobs" --no-parallelize-within-files --parallel-binary-name rush {{ justfile_directory() }}/tests/
        ;;
    abort)
        # --abort makes bats pass --halt to the parallel runner, which rush
        # does not support, so fail-fast has to run serially.
        bats --print-output-on-failure --abort {{ justfile_directory() }}/tests/
        ;;
    *)
        echo "Unknown mode '{{ mode }}' (expected: parallel, abort)" >&2
        exit 2
        ;;
    esac
