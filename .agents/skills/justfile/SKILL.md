---
name: justfile
description: "Use when invoked as $justfile or when creating, editing, reviewing, or adding recipes to a justfile, Justfile, or *.just file."
---

# Justfile Skill

Generate or update a project's `justfile`, `Justfile`, or `*.just` file following
the conventions below. This skill is the single source of truth for Just
task-runner conventions across every coding agent; harness-specific rules load
it rather than repeating it.

## When to Use

- Project initialization (new repo setup) — check for a justfile and offer to
  create one
- User asks to add a justfile, `Justfile`, or recipes to a `*.just` file
- User asks to add build/test/lint/format automation to a project
- Reviewing an existing justfile for convention drift

## Process

### Step 1: Detect Project

Determine the project type by checking for key files:

| File(s)                        | Project Type |
|---------------------------------|--------------|
| `Cargo.toml`                    | Rust         |
| `package.json`                  | Node.js      |
| `pyproject.toml`, `setup.py`    | Python       |
| `go.mod`                        | Go           |
| `build.gradle*`, `pom.xml`      | JVM          |
| `*.xcodeproj`, `Package.swift`  | Swift/Apple  |
| `Makefile` (alone)              | C/C++        |
| `Gemfile`                       | Ruby         |
| `mix.exs`                       | Elixir       |

If multiple indicators exist, note the primary language. Detect the specific
toolchain in use (e.g. `uv` vs `pip` for Python, `pnpm` vs `npm` for Node) from
lockfiles and config so generated recipes call real, project-specific commands
— never placeholders.

### Step 2: Check for an Existing File

Just accepts either `justfile` or `Justfile` as the conventional entry-point
filename — never both. On this repository's filesystem (case-insensitive
macOS/APFS by default), the two names collide as the same file, so pick one
and stay consistent within a project. A `*.just` file is used only when
referenced explicitly via `--justfile`/`import`/`mod`.

```bash
ls justfile Justfile *.just 2>/dev/null
```

- **Existing root file found**: Read it, then offer to add missing standard
  recipes or fix convention violations. Preserve every working recipe; never
  rewrite one you weren't asked to change.
- **Existing `*.just` file being edited**: apply the same conventions to it.
  Only the file that `just` treats as the entry point (`justfile`/`Justfile`)
  needs the settings block and `_default` recipe; an imported `*.just` file
  does not repeat them.
- **Missing**: Generate a new one (Step 3). Default to lowercase `justfile`
  unless the project already prefers `Justfile` or the user asks for it.

### Step 3: Generate or Update

Build the justfile from these blocks, in order:

#### 3a. Settings Header

Always include, at the top of the root file:

```just
set ignore-comments
set script-interpreter := ['bash', '-eu']
set unstable
```

- Do **not** add global `set quiet`. Prefix only the individual command lines
  that should be hidden with `@`; leave the rest visible.
- Do **not** add global `set export`. Use `export NAME := ...` only for a
  specific value a recipe or its child process needs as a real environment
  variable; otherwise reference the value with `{{ name }}` interpolation.
- `set unstable` is an independent convention for this project (it enables
  unstable Just features). It is not required by `--fmt` — see 3e.

#### 3b. Default Recipe

Always include this exact block immediately after settings and before every
other recipe:

```just
[default]
_default:
    @just --list
```

- Keep `_default` underscore-private (unlisted in `--list` output), explicitly
  marked `[default]`, first by convention, and silent via the leading `@`.
- Do **not** use `[script]` for this recipe: an `@`-prefixed line inside a
  `[script]` recipe is passed to the interpreter literally and fails, since
  script bodies aren't line-by-line shell invocations. The plain (non-script)
  form runs `@just --list` as intended.

#### 3c. Lifecycle Recipes (project-specific)

Select recipes from the table below based on the detected project type. Only
include recipes that make sense for the project — don't add `deploy` to a
library, don't add `build` to a pure script project.

| Recipe    | Group           | Rust            | Node.js                        | Python                     | Go                   | Swift/Apple             | JVM                       |
|-----------|-----------------|-----------------|---------------------------------|------------------------------|-----------------------|---------------------------|-----------------------------|
| `deps`    | `configuration` | —               | `pnpm install` / `npm install` | `uv sync`                   | `go mod download`    | —                        | —                          |
| `build`   | `build`         | `cargo build`   | per-project                     | —                             | `go build ./...`     | `swift build`            | `./gradlew build`          |
| `test`    | `tests`         | `cargo test`    | `pnpm test` / `npm test`       | `uv run pytest`             | `go test ./...`      | `swift test`             | `./gradlew test`           |
| `lint`    | `checks`        | `cargo clippy`  | `pnpm lint` / `eslint .`       | `uv run ruff check .`       | `golangci-lint run`  | `swiftlint`              | `./gradlew lint`           |
| `format`  | `configuration` | `cargo fmt`     | `prettier --write .`           | `uv run ruff format .`      | `gofmt -w .`          | `swift format format .`  | `./gradlew spotlessApply`  |
| `run`     | `build`         | `cargo run`     | per-project                     | per-project                   | `go run .`            | `swift run`              | `./gradlew run`            |
| `clean`   | `configuration` | `cargo clean`   | `rm -rf node_modules dist`     | `rm -rf .venv __pycache__`  | `go clean`            | `swift package clean`    | `./gradlew clean`          |

Use `[script]` with `set -euo pipefail` for multi-line Bash recipes instead of
line continuations. Add descriptive parameters (`recipe-name param:`) and
`*args` for variadic pass-through (`recipe-name *args:`). Use aliases for
common shortcuts (`alias t := test`). Use kebab-case for recipe names. Keep a
recipe's doc comment on the line directly above it — Just renders that
comment as the recipe's help text in `--list` output.

#### 3d. Grouping Threshold

- **Fewer than 10 non-default recipes**: do NOT add `[group('name')]`
  attributes or group comment blocks. Keep the file flat and simple.
- **10 or more non-default recipes**: organize every recipe with a
  `[group('name')]` attribute and separate groups with a comment block:

  ```just
  #
  # group-name group recipes
  #

  [group('group-name')]
  recipe-name:
      command
  ```

When an edit pushes the recipe count from 9 to 10 or more, apply grouping to
the whole file in that same edit — not just the new recipe — so the file
never sits at the threshold half-grouped.

#### 3e. Formatting

- `just --fmt` rewrites the file's formatting; `just --fmt --check` verifies
  formatting without writing. Neither command requires `set unstable` on
  current Just versions.
- When adding a `format` recipe, end it with `just --fmt` so the justfile
  itself gets normalized alongside the rest of the project:

  ```just
  # Auto-format code and the justfile
  [group('configuration')]
  format:
      # project-specific formatter here
      just --fmt
  ```

### Step 4: Rename Suggestions

When actively editing an existing justfile for another reason, check whether
it defines a recipe named `install` and, if so, suggest renaming it to `deps`
(clearer intent — installs dependencies, not the app). Only surface this as a
suggestion during an active edit to the file; never open a change, PR, or
commit solely to perform the rename.

### Step 5: Write and Verify

1. Write the file.
2. Run `just --fmt --justfile <path>` to normalize formatting.
3. Run `just --list --justfile <path>` (or `just --justfile <path>` for the
   default recipe) to verify it parses correctly and lists the expected
   recipes.
4. Report what was generated or changed.

## Conventions Reference

- Kebab-case recipe names.
- `[group('name')]` attributes and separating comment blocks only once the
  file has 10 or more non-default recipes; omit both below that threshold.
- `[script]` attribute plus `set -euo pipefail` for multi-line Bash recipes.
- Prefer per-line `@` over per-recipe/global `set quiet` when only some lines
  in a recipe should be silent.
- Prefer `{{ name }}` interpolation over `export NAME := ...`; reserve
  `export` for values a spawned process must read from its environment.

## Do NOT

- Add recipes for tools the project doesn't use.
- Add a `deploy` recipe without knowing the deployment target.
- Overwrite an existing justfile without asking.
- Include placeholder commands — every recipe must run something real.
- Add global `set quiet` or global `set export`.
- Use `[script]` for the one-line `_default` recipe.
