---
name: justfile
description: |-
  Generate a justfile for a project, or add recipes to an existing one.
  Use when initializing a new project, setting up a justfile, adding build/test/lint recipes,
  or when the user mentions "justfile", "just recipe", "just task runner", or "add a just recipe".
---

# Justfile Skill

Generate or update a project's justfile following the conventions in the `justfile` rule.

## When to Use

- Project initialization (`/init`, new repo setup) — check for a justfile and offer to create one
- User asks to add a justfile or just recipes
- User asks to add build/test/lint/format automation to a project

## Process

### Step 1: Detect Project

Determine the project type by checking for key files:

| File(s)                        | Project Type |
|--------------------------------|-------------|
| `Cargo.toml`                   | Rust        |
| `package.json`                 | Node.js     |
| `pyproject.toml`, `setup.py`   | Python      |
| `go.mod`                       | Go          |
| `build.gradle*`, `pom.xml`     | JVM         |
| `*.xcodeproj`, `Package.swift` | Swift/Apple |
| `Makefile` (alone)             | C/C++       |
| `Gemfile`                      | Ruby        |
| `mix.exs`                      | Elixir      |

If multiple indicators exist, note the primary language.

### Step 2: Check for Existing Justfile

```bash
ls justfile 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

- **EXISTS**: Read it, then offer to add missing standard recipes or fix convention violations.
- **MISSING**: Generate a new one (Step 3).

### Step 3: Generate Justfile

Build the justfile from these blocks, in order:

#### 3a. Settings Header (always)

```just
set export
set ignore-comments
set script-interpreter := ['bash', '-eu']
set quiet
set unstable
```

#### 3b. Default Recipe (always)

```just
[script]
_default:
    just --list
```

#### 3c. Lifecycle Recipes (project-specific)

Select recipes from the table below based on the detected project type. Only include recipes that make sense for the project — don't add `deploy` to a library, don't add `build` to a pure script project.

| Recipe    | Group             | Rust                        | Node.js                          | Python                       | Go                          | Swift/Apple              | JVM                           |
|-----------|-------------------|-----------------------------|----------------------------------|------------------------------|-----------------------------|--------------------------|-------------------------------|
| `deps`    | `configuration`   | —                           | `pnpm install` / `npm install`   | `uv sync`                   | `go mod download`           | —                        | —                             |
| `build`   | `build`           | `cargo build`               | per-project                      | —                            | `go build ./...`            | `swift build`            | `./gradlew build`             |
| `test`    | `tests`           | `cargo test`                | `pnpm test` / `npm test`         | `uv run pytest`             | `go test ./...`             | `swift test`             | `./gradlew test`              |
| `lint`    | `checks`          | `cargo clippy`              | `pnpm lint` / `eslint .`         | `uv run ruff check .`       | `golangci-lint run`         | `swiftlint`              | `./gradlew lint`              |
| `format`  | `configuration`   | `cargo fmt`                 | `prettier --write .`             | `uv run ruff format .`      | `gofmt -w .`                | `swift format format .`  | `./gradlew spotlessApply`     |
| `run`     | `build`           | `cargo run`                 | per-project                      | per-project                  | `go run .`                  | `swift run`              | `./gradlew run`               |
| `clean`   | `configuration`   | `cargo clean`               | `rm -rf node_modules dist`       | `rm -rf .venv __pycache__`   | `go clean`                  | `swift package clean`    | `./gradlew clean`             |

Use `[script]` attribute for multi-line recipes. Add `set -euo pipefail` at the top of script bodies.

#### 3d. Grouping Threshold

- **< 10 recipes**: Do NOT add `[group()]` attributes or group comment blocks. Keep the justfile flat and simple.
- **>= 10 recipes**: Organize with `[group('name')]` attributes and comment blocks between groups, per the `justfile` rule.

When updating an existing justfile, count total recipes (excluding `_default`) to decide whether to add or remove groups.

#### 3e. Format Recipe with just --fmt

Always include a `format` recipe that also runs `just --fmt`:

```just
# Auto-format code and justfile
[script]
format:
    set -euo pipefail
    # project-specific formatter here
    just --fmt
```

### Step 4: Write and Verify

1. Write the justfile
2. Run `just --fmt` to normalize formatting
3. Run `just --list` to verify it parses correctly
4. Report what was generated

## Conventions Reference

All conventions from the `justfile` rule apply:
- Kebab-case recipe names
- `[group('name')]` attributes only when >= 10 recipes; omit for smaller justfiles
- Comment blocks between groups (only when using groups)
- `[script]` attribute for multi-line recipes
- Aliases for common shortcuts (`alias t := test`)

## Do NOT

- Add recipes for tools the project doesn't use
- Add a `deploy` recipe without knowing the deployment target
- Override an existing justfile without asking
- Include placeholder commands — every recipe must run something real
