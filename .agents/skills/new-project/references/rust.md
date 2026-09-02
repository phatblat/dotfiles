# Rust (cargo) Reference

## 1. Pin tools

```bash
mise use --pin just@latest rust@latest
```

## 2. `mise.toml`

`[tools]` only — there is **no `mise deps` provider for cargo**, so this
stack gets no `[deps.*]` block and no `[settings]` block (nothing needs
`experimental = true`):

```toml
[tools]
just = "<pinned>"
rust = "<pinned>"
```

Then run `mise trust && mise fmt`.

## 3. Native init

```bash
cargo init --name <name> --vcs none
```

## 4. Test

Extract the greeting into `fn greeting() -> String` so `main` has something
extracted to call, then append a real `#[cfg(test)] mod tests` to
`src/main.rs` exercising it:

```rust
fn greeting() -> String {
    "Hello, world!".to_string()
}

fn main() {
    println!("{}", greeting());
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greeting_says_hello() {
        assert_eq!(greeting(), "Hello, world!");
    }
}
```

## 5. `.gitignore`

```gitignore
/target
```

## 6. `justfile`

Same header and `_default` block as the Python template (see
`references/python.md`). 11 non-default recipes, so grouping applies.

- `deps` (configuration): `mise install` then `cargo fetch`
- `format` (configuration): `cargo fmt` then `mise fmt` then `just --fmt`
- `clean` (configuration): `cargo clean`
- `outdated` (configuration): `-mise outdated --local --bump` then
  `-cargo update --dry-run`
- `upgrade` (configuration): `mise upgrade --local --bump --yes` then
  `cargo update`
- `build` (build): `cargo build`
- `run` (build): `cargo run`
- `format-check` (checks): `cargo fmt --check` then `mise fmt --check` then
  `just --fmt --check`
- `lint` (checks): `cargo clippy --all-targets -- -D warnings`
- `check` (checks): `check: format-check lint test`
- `test` (tests): `cargo test`

`cargo update` only moves dependency versions within the ranges already
declared in `Cargo.toml` — it never rewrites a manifest requirement to a new
major version. Bumping requirements themselves needs `cargo upgrade` from the
separately installed `cargo-edit` plugin, which this scaffold does not pin.
So `upgrade` here bumps the mise pins and refreshes `Cargo.lock` within the
existing ranges only; it is not a substitute for a deliberate manifest review.

Full file:

```just
set ignore-comments
set script-interpreter := ['bash', '-eu']
set unstable

[default]
_default:
    @just --list

#
# configuration group recipes
#

# Install pinned tools and fetch dependencies
[group('configuration')]
deps:
    mise install
    cargo fetch

# Format source, mise config, and the justfile
[group('configuration')]
format:
    cargo fmt
    mise fmt
    just --fmt

# Remove build output
[group('configuration')]
clean:
    cargo clean

# Report tools and dependencies with newer versions available
[group('configuration')]
outdated:
    -mise outdated --local --bump
    -cargo update --dry-run

# Upgrade pinned tools and refresh the lockfile within existing ranges
[group('configuration')]
upgrade:
    mise upgrade --local --bump --yes
    cargo update

#
# build group recipes
#

# Build the project
[group('build')]
build:
    cargo build

# Run the application
[group('build')]
run:
    cargo run

#
# checks group recipes
#

# Verify formatting without writing changes
[group('checks')]
format-check:
    cargo fmt --check
    mise fmt --check
    just --fmt --check

# Lint with clippy, denying warnings
[group('checks')]
lint:
    cargo clippy --all-targets -- -D warnings

# Run every gate: formatting, lint, tests
[group('checks')]
check: format-check lint test

#
# tests group recipes
#

# Run the test suite
[group('tests')]
test:
    cargo test
```
