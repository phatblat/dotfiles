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
| `generate` | `build`         | per-project     | per-project                     | per-project                   | `go generate ./...`  | per-project              | per-project                |
| `build`   | `build`         | `cargo build`   | per-project                     | —                             | `go build ./...`     | `swift build`            | `./gradlew build`          |
| `test`    | `tests`         | `cargo test`    | `pnpm test` / `npm test`       | `uv run pytest`             | `go test ./...`      | `swift test`             | `./gradlew test`           |
| `lint`    | `checks`        | `cargo clippy`  | `pnpm lint` / `eslint .`       | `uv run ruff check .`       | `golangci-lint run`  | `swiftlint`              | `./gradlew lint`           |
| `format`  | `configuration` | `cargo fmt`     | `prettier --write .`           | `uv run ruff format .`      | `gofmt -w .`          | `swift format format .`  | `./gradlew spotlessApply`  |
| `run`     | `build`         | `cargo run`     | per-project                     | per-project                   | `go run .`            | `swift run`              | `./gradlew run`            |
| `clean`   | `configuration` | `cargo clean`   | `rm -rf node_modules dist`     | `rm -rf .venv __pycache__`  | `go clean`            | `swift package clean`    | `./gradlew clean`          |

The `outdated` and `upgrade` recipes are lifecycle recipes too, but their
commands are longer and carry per-toolchain caveats — see 3f for the table.

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

When an edit takes the count from below 10 to 10 or more, apply grouping to the
whole file in that same edit — not just the new recipes — so the file never
sits at the threshold half-grouped. Count the recipes the edit adds together,
not one at a time: adding both `outdated` and `upgrade` to a file with eight
recipes crosses the threshold and triggers grouping.

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

#### 3f. Update Recipes (`outdated` / `upgrade`)

These two recipes are a matched pair with a strict division of labor:

- **`outdated`** reports what *could* change and writes nothing — no lockfile,
  no manifest, no `node_modules`. It is safe to run at any time, including on
  a dirty tree.
- **`upgrade`** applies the updates and leaves the project in a consistent,
  installed state. Refreshing a lockfile without re-syncing the environment is
  a half-done upgrade, so chain the sync step when the toolchain separates the
  two (`uv lock --upgrade && uv sync`, `go get -u ./... && go mod tidy`).

Wherever the toolchain offers a dry-run flag, define `outdated` as the exact
dry-run of `upgrade` — `cargo update --dry-run` against `cargo update`,
`uv lock --upgrade --dry-run` against `uv lock --upgrade`,
`swift package update --dry-run` against `swift package update`. That symmetry
makes `outdated` a trustworthy preview instead of a second,
differently-scoped query.

| Project type | `outdated`                       | `upgrade`                        |
|--------------|----------------------------------|----------------------------------|
| Rust         | `cargo update --dry-run`         | `cargo update`                   |
| Node.js      | `pnpm outdated` / `npm outdated` | `pnpm update` / `npm update`     |
| Python (uv)  | `uv lock --upgrade --dry-run`    | `uv lock --upgrade && uv sync`   |
| Go           | `go list -u -m all`              | `go get -u ./... && go mod tidy` |
| Swift/Apple  | `swift package update --dry-run` | `swift package update`           |
| Ruby         | `bundle outdated`                | `bundle update`                  |
| Elixir       | `mix hex.outdated`               | `mix deps.update --all`          |
| JVM (Maven)  | `mvn versions:display-dependency-updates` | `mvn versions:use-latest-releases` |
| JVM (Gradle) | `./gradlew dependencyUpdates`    | —                                |

Toolchain caveats that decide whether a recipe belongs in the file at all:

- **Gradle has no built-in upgrade task.** Leave `upgrade` out rather than
  inventing one, and only add `outdated` when the build actually applies the
  `com.github.ben-manes.versions` plugin — the task does not exist otherwise.
- **Rust:** `cargo update --dry-run` only reports moves allowed by the
  existing `Cargo.toml` requirements, so a dependency pinned below a new major
  looks current. `cargo outdated` reports that manifest-level staleness, and
  `cargo upgrade` rewrites the requirements, but both come from separately
  installed plugins (`cargo-outdated`, `cargo-edit`). Use them only when the
  project already depends on them.
- **Python:** prefer the lockfile-level `uv lock --upgrade --dry-run` over
  `uv pip list --outdated`, which needs an already-synced virtualenv. For a
  Poetry project use `poetry show --outdated` and `poetry update`.
- **System dependencies are a separate layer.** The table covers a project's
  *language* dependencies. A project that also needs Homebrew formulae declares
  them in a `Brewfile`, upgraded with `brew bundle upgrade --file=Brewfile`.
  There is no `brew bundle outdated`, so there is nothing to add to a project
  `outdated` recipe — see the `homebrew` skill.

`upgrade` means "move to the newest versions the manifest already permits, then
refresh the lockfile." Rewriting manifests to new major versions is a
breaking-change review, not a one-word recipe — keep it a deliberate, separate
action rather than hiding it behind `just upgrade`. Every mature toolchain
splits these the same way: `pnpm update` vs `pnpm update --latest`,
`cargo update` vs `cargo upgrade`, `mise upgrade` vs `mise upgrade --bump`.

##### Tolerate the "updates found" exit code

Several tools treat "updates are available" as a failure and exit non-zero,
which aborts the recipe even though nothing went wrong:

| Command                | Exit when updates found |
|------------------------|-------------------------|
| `npm outdated`         | `1`                     |
| `pnpm outdated`        | `1`                     |
| `bundle outdated`      | `1`                     |
| `rustup check`         | `100`                   |

`bun outdated`, `cargo update --dry-run`, `uv lock --upgrade --dry-run`,
`go list -u -m all`, and `swift package update --dry-run` all exit `0`. Apply
the tolerance to every `outdated` recipe anyway — it costs nothing on the
well-behaved commands and keeps the recipe correct if a tool changes its mind.

In a normal recipe, prefix the line with `-` to ignore its exit status; combine
it with `@` as `-@` when the line should also be silent:

```just
# Report dependencies with newer versions available
[group('configuration')]
outdated:
    -pnpm outdated
```

In a `[script]` recipe the `-` prefix does not apply — the body is one Bash
program, so `set -euo pipefail` aborts on the first failure. Use `|| true` on
the individual command instead:

```just
# Report outdated dependencies and toolchain versions
[script]
[group('configuration')]
outdated:
    set -euo pipefail
    pnpm outdated || true
    rustup check || true
```

Leave the `-` prefix and `|| true` off `upgrade`: there, a non-zero exit is a
genuine failure that must surface.

##### Scope: project tools, never the machine

"Installed tools" means the toolchain this project pins, not everything on the
developer's machine. Include a project-scoped version manager when the repo
actually pins one — `mise` alongside a `mise.toml` or `.tool-versions`, or
`rustup check` alongside a `rust-toolchain.toml`.

**Always state the mise scope explicitly.** Bare `mise` commands infer scope
from the working directory: `mise use` writes the project `mise.toml`, *except*
that it writes the global `~/.config/mise/config.toml` when the cwd is your
home directory. The same command therefore edits different files depending on
where it runs, which is exactly the kind of invisible default a justfile should
eliminate. Scope flags are not uniform across subcommands — verified:

| Command         | `--local` | `--global` | Meaning of the scope flag                 |
|-----------------|-----------|------------|-------------------------------------------|
| `mise outdated` | yes       | no         | Filter: only tools declared in the project's `mise.toml` |
| `mise upgrade`  | yes       | no         | Filter: only upgrade tools declared in the project's `mise.toml` |
| `mise use`      | no        | yes        | Target: write the global config instead of the project's |
| `mise install`  | no        | no         | Acts on the resolved config for the cwd   |

On `outdated` and `upgrade`, `--local` is a *filter*, not a write target — it
restricts the operation to tools the project declares, so `just outdated` in a
project never reports the developer's global tools as stale. That is what a
project justfile wants:

```just
# Reports project-pinned tools with newer versions available
outdated:
    -mise outdated --local

# Upgrades project-pinned tools within the ranges in mise.toml
upgrade:
    mise upgrade --local --yes
```

A dotfiles justfile is the mirror image: there the machine *is* the project, so
`--global` on `mise use` is correct and deliberate, because
`~/.config/mise/config.toml` is the baseline every other directory inherits.

Never spell these flags with `-l`. Today `-l` is a deprecated shorthand for
`--bump`, and mise has announced that after removal `-l` becomes shorthand for
`--local` — so a recipe using `-l` will silently change meaning from "upgrade
to latest" to "only local tools". Write `--bump` and `--local` in full.

**Package managers that own the whole machine stay out of a project justfile.**
A recipe running bare `brew upgrade`, `brew outdated`, or an OS package manager
mutates or reports state far outside the repo and surprises everyone who clones
it. Those belong in a personal dotfiles justfile.

Homebrew is fine in a project justfile when it is scoped to a project manifest:
`brew bundle install --file=Brewfile --no-upgrade` installs only what the repo
declares. See the `homebrew` skill for the `Brewfile` conventions, including
why bare `brew bundle install` is the wrong command for a `deps` recipe.

`upgrade` is a dependency-lifecycle mutation, so it belongs in the
`configuration` group next to `deps`. `outdated` only reads, so put it in the
file's informational group if one exists (`info`, `query`) and in
`configuration` otherwise. Neither belongs in `checks`: that group is for gates
that *should* fail CI, and an available dependency update is not a failure.

#### 3g. Build, Generate, and Clean

- Lifecycle recipes are the discovery surface: an agent or new contributor
  runs `just --list` and expects `deps`, `build`, `test`, `lint`, `format`,
  `clean`, `outdated`, `upgrade` to mean the same thing in every repo. Prefer
  wiring a new step into one of those names over inventing a project-specific
  verb.
- When a repo checks in generated artifacts, give the generator a `generate`
  recipe and make `build` depend on it, so one `just build` reproduces every
  derived output. Any tool built from checked-in source gets its build step
  added as a `build` dependency rather than a standalone name nobody
  discovers.
- Put `generate` in the `build` group, not `checks`. Generation writes files;
  `checks` is for gates that fail CI. The paired validator (`--check`/
  `--dry-run` form) does belong in `checks`.
- Intermediary build artifacts must be gitignored **and** purgeable by
  `clean`. Ignoring without purging leaves dead bytes; purging without
  ignoring leaves status noise. The repo's own `.gitignore` owns the entry —
  do not rely on a tool writing a self-ignoring `.gitignore` inside its own
  output directory.
- `clean` covers three categories, and decomposing it into one recipe per
  category is worth it as soon as their costs differ: package-manager
  download/cache/temp directories (`clean-caches`), source build output
  (`clean-build`), and installed dependency trees plus throwaway virtualenvs
  (`clean-deps`). Cache purges cost network re-download; build-output purges
  cost seconds. A developer who wants the cheap one should not have to pay for
  the expensive one.
- Scope `clean` to the repo. Enumerate the source roots to scan explicitly;
  never `find` from `$HOME` and never `git clean -X`, which deletes every
  gitignored file in the tree.
- `clean` must not delete tracked files. Gate each removal on the directory
  containing no tracked files (`git ls-files -- "$dir"` empty), so an
  artifact-shaped name that is deliberately checked in survives.
- Keep expensive-to-restore data out of `clean`. Downloaded model weights,
  datasets, and container images are data, not build output; excluding them
  needs a comment saying why, or the next reader adds them back.
- If `clean` removes an installed dependency tree, `deps` must restore it. A
  `clean`/`deps` pair that does not round-trip is a trap: the machine ends up
  in a state no recipe repairs.
- Vendored third-party trees with their own build/upgrade flow stay out of
  both `build` and `clean`. Purging output that `just build` cannot
  regenerate is a one-way door.
- Guard every tool invocation in a `clean` script with `command -v`: `[script]`
  recipes run under `-e`, so one missing binary aborts the rest of the purge.

### Step 4: Rename Suggestions

When actively editing an existing justfile for another reason, check for these
recipe names and suggest the clearer convention:

| Existing   | Suggest    | Why |
|------------|------------|-----|
| `install`  | `deps`     | Installs dependencies, not the app. |
| `update`   | `upgrade`  | `update` doesn't say what gets updated; `upgrade` pairs with `outdated`. |

Before suggesting the `update` → `upgrade` rename, read the recipe body: if it
only *reports* available updates rather than applying them, it is really an
`outdated` recipe and should be renamed to that instead.

Only surface these as suggestions during an active edit to the file; never open
a change, PR, or commit solely to perform a rename.

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
- `outdated` never writes; `upgrade` applies updates and re-syncs the
  environment. `upgrade` goes in `configuration` beside `deps`; `outdated` goes
  in the file's informational group when it has one. Neither goes in `checks`.
- Tolerate the "updates found" non-zero exit in `outdated` (`-` line prefix, or
  `|| true` inside a `[script]` recipe); never mask failures in `upgrade`.
- `generate` writes derived artifacts and lives in the `build` group; `build`
  depends on it so one command reproduces every checked-in-source output.
- Build artifacts are both gitignored by the repo's own `.gitignore` and
  purged by `clean`; `clean` never deletes tracked files, is scoped to
  enumerated repo roots, excludes expensive-to-restore data, and round-trips
  with `deps`.

## Do NOT

- Add recipes for tools the project doesn't use.
- Add a `deploy` recipe without knowing the deployment target.
- Overwrite an existing justfile without asking.
- Include placeholder commands — every recipe must run something real.
- Add global `set quiet` or global `set export`.
- Use `[script]` for the one-line `_default` recipe.
- Put a machine-wide package manager (`brew upgrade`, `brew outdated`, OS
  package managers, `mise use --global`) in a project justfile. Manifest-scoped
  Homebrew (`brew bundle install --file=Brewfile --no-upgrade`) is fine.
- Rely on an implicit `mise` scope, or abbreviate `--local`/`--bump` to `-l`.
- Let `outdated` mutate a lockfile, manifest, or installed dependency tree.
- Add a `clean` recipe that runs `git clean -X`, or one that `find`s from
  `$HOME`.
- Purge a build output that no recipe can regenerate, or a dependency tree
  that `deps` does not restore.
- Ignore a build artifact without also purging it in `clean`, or rely on a
  tool's self-written `.gitignore` instead of the repo's.
