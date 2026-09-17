# rust — toolchain management, the ness compiled guard, and the wt worktree resolver

# Installs the Rust toolchain and llvm-tools component (rust-objcopy needs
# libLLVM.dylib from llvm-tools to strip debug info; see profile.release.strip
# in crates/ness/Cargo.toml)
[group('rust')]
[script]
install-rust-deps:
    set -euo pipefail
    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    fi
    rustup toolchain install stable
    rustup component add llvm-tools --toolchain stable

# Update Rust toolchains
[group('rust')]
[script]
update-rust:
    set -euo pipefail
    rustup update

# Remove non-default Rust toolchains except stable and unpinned nightly
[group('rust')]
[script]
clean-rust:
    set -euo pipefail
    in_section=false
    rustup show | while IFS= read -r line; do
        if [[ "$line" == "installed toolchains" ]]; then
            in_section=true
            continue
        fi
        if [[ "$line" == "active toolchain" ]]; then
            break
        fi
        if ! $in_section || [[ "$line" == -* ]] || [[ -z "$line" ]]; then
            continue
        fi
        toolchain="${line%% *}"
        if [[ "$line" == *"(default)"* ]] || [[ "$toolchain" == stable-* ]] || { [[ "$toolchain" == nightly-* ]] && [[ ! "$toolchain" =~ ^nightly-[0-9] ]]; }; then
            echo "keeping: $toolchain"
            continue
        fi
        echo "removing: $toolchain"
        rustup toolchain uninstall "$toolchain"
    done

# Builds the ness compiled guard (release profile)
[group('rust')]
ness-build: install-rust-deps
    cargo build --release --manifest-path {{ justfile_directory() }}/crates/ness/Cargo.toml

# Installs the ness compiled guard to ~/.local/bin, the path every harness hook execs, then checks it against the corpus
[group('rust')]
ness-install: ness-build && ness-check-installed
    install -m 755 {{ justfile_directory() }}/crates/ness/target/release/ness {{ env("HOME") }}/.local/bin/ness

# CI: agent-harness-parity.yml (ness job)
# Runs the ness guard's corpus, shim, and fail-closed tests
[group('rust')]
ness-test: install-rust-deps
    cargo test --locked --manifest-path {{ justfile_directory() }}/crates/ness/Cargo.toml

# Checks the installed ~/.local/bin/ness (the copy every harness hook runs) against the corpus
[group('rust')]
ness-check-installed: install-rust-deps
    NESS_CHECK_INSTALLED=1 cargo test --locked --manifest-path {{ justfile_directory() }}/crates/ness/Cargo.toml installed_copy_matches_corpus

# Builds the wt worktree resolver (release profile)
[group('rust')]
wt-build: install-rust-deps
    cargo build --release --manifest-path {{ justfile_directory() }}/crates/wt/Cargo.toml

# Installs the wt resolver to ~/.local/bin, the path the shell wrappers exec
[group('rust')]
wt-install: wt-build
    install -m 755 {{ justfile_directory() }}/crates/wt/target/release/wt {{ env("HOME") }}/.local/bin/wt

# CI: agent-harness-parity.yml (wt job)
# Runs the wt resolver's worktree and overlay integration tests
[group('rust')]
wt-test: install-rust-deps
    cargo test --locked --manifest-path {{ justfile_directory() }}/crates/wt/Cargo.toml
