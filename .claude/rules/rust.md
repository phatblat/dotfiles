---
paths:
  - "**/*.rs"
  - "Cargo.toml"
  - "Cargo.lock"
---

# Rust Conventions

## Tooling
- Build/check: `cargo check`
- Tests: `cargo test`
- Linter: `cargo clippy`
- Formatter: `cargo fmt`

## Validation Command
After writing Rust code, always suggest: `cargo check && cargo test`
