---
name: new-project
description: "Use when invoked as $new-project or when creating a brand-new repository or project from scratch — scaffolds mise-pinned tools, a just task surface, the standard repo files, and CI for Python (uv), TypeScript (bun), Rust (cargo), or Go."
---

# New-Project Skill

Scaffold a brand-new repository so `mise` owns every pinned tool and `just`
owns every command — even where the language's package manager could run
scripts, because `just --list` is the discovery surface every harness and
human uses to find what a project can do. Four stacks are supported: Python
(uv), TypeScript (bun), Rust (cargo), and Go. Tool versions are never
hardcoded in this skill; they are resolved to the latest GA release at
scaffold time via `mise use --pin <tool>@latest`.

## When to Use

- The user asks to create a brand-new repository or project from scratch in
  one of the four supported stacks.
- Invoked explicitly as `$new-project`.

## When Not to Use

- Adding a justfile to an *existing* project — that is the `justfile` skill's
  job. Read it directly.
- Adding a `Brewfile` to a project — that is the `homebrew` skill's job.
- A stack outside Python/TypeScript/Rust/Go. Do not improvise a fifth
  template; tell the user the stack is unsupported.

## Inputs

Collect before starting, asking the user for whatever is not already given:

- **Project name** (kebab-case).
- **One-line description** (used in `README.md` and the skill's frontmatter is
  not touched — this is the *project's* description, not the skill's).
- **Stack**: Python, TypeScript, Rust, or Go.
- **Target directory**: defaults to the current directory when it is empty,
  otherwise `./<name>`. **Never scaffold over a non-empty directory without
  asking first** — confirm with the user before writing into a directory that
  already has files in it.
- **Go only**: module path, default `github.com/phatblat/<name>`; ask, and use
  the answer when given.

## Authority

Before writing or editing any justfile, read `~/.agents/skills/justfile/SKILL.md`
first — it is the source of truth for Just conventions (settings header,
`_default` recipe, the 10-recipe grouping threshold, the `outdated`/`upgrade`
pair, and mise scope flags). The per-stack templates in `references/` already
conform to it. Anything a template does not cover follows that skill.

## Shared Sequence

Stack-independent steps, in order. Full stack-specific commands, manifests,
and file bodies live in `references/<stack>.md` — read the matching file
before step 2.

1. `mkdir -p <dir> && cd <dir>`
2. `mise use --pin <tool>@latest …` for the stack's tool list (see the
   reference file). This creates `mise.toml` and installs the tools.
3. Append the stack's `[deps.*]` and `[settings]` blocks with their comments
   (see the reference file — Rust has neither, since no `mise deps` provider
   exists for cargo), then run `mise trust` and `mise fmt`.
4. Run the stack's native init (see the reference file).
5. Write `justfile` from the stack template, substituting the project name.
6. Write `.gitignore`, `README.md`, `LICENSE.md`, `.editorconfig`, `AGENTS.md`,
   and `.github/workflows/ci.yml` from the shared templates below.
7. Write the stack's one real test (see the reference file).
8. `git init -b main`, `git add -A`, and create the initial commit with
   subject `feat: initial project scaffold`, appending the harness
   attribution trailer required by `~/.agents/harness/instructions.md`.
9. Run `just check` and report the result. A red `just check` is a scaffold
   failure, not a caveat — fix it before telling the user the project is
   ready.

## Shared File Templates

These five files are identical across every stack except where noted.

### `LICENSE.md`

```markdown
The MIT License (MIT)

Copyright © <current year> Ben Chatelain

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### `.editorconfig`

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_size = 2
indent_style = space
trim_trailing_whitespace = true

# Trailing spaces have meaning in Markdown
[*.md]
trim_trailing_whitespace = false
```

Add a stack-specific override block at the end:

- Go: `[*.{go}]` with `indent_style = tab`.
- Rust and Python: `[*.{rs,py}]` with `indent_size = 4`.
- TypeScript: no override — the base 2-space block already applies.

### `README.md`

```markdown
# <name>

<description>

## Development

\`\`\`bash
just deps    # install pinned tools and dependencies
just check   # formatting, lint, types, tests
\`\`\`

`just --list` shows every recipe.

## License

MIT © Ben Chatelain
```

### `AGENTS.md`

```markdown
# Repository Guidelines

## Toolchain

`mise.toml` pins every tool; `just` is the only command surface. Prefer adding a
recipe over documenting a raw command, and run tools through the recipes so the
pinned versions are the ones that execute.

## Commands

- `just deps` — install pinned tools and project dependencies
- `just check` — the full gate: formatting, lint, types, tests
- `just test` — tests only
- `just outdated` / `just upgrade` — report, then apply, tool and dependency updates

## Conventions

- Formatting is owned by the formatter. Run `just format`; never hand-format.
- Add a test with every behavior change; `just check` must be green before pushing.
```

### `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: jdx/mise-action@3c2e0cf82a5b2e5249f0d3635a4d83d0ae861518 # v4.2.5
      - run: just deps
      - run: just check
```

The action's own `mise install` auto-trusts the project config, which is what
makes the `[settings] experimental = true` block take effect for `mise deps`
in CI. Do not also pass `experimental: true` to the action — one source of
truth.

## Conventions That Hold Across Every Stack

- Versions are resolved at scaffold time by `mise use --pin <tool>@latest`.
  Never copy a version number out of this skill or a reference file.
- Every stack crosses the `justfile` skill's 10-recipe grouping threshold, so
  **every** recipe carries a `[group(...)]` attribute and the groups are
  separated by `#\n# <name> group recipes\n#` comment blocks. Group order:
  `configuration`, `build`, `checks`, `tests`.
- Group assignment: `deps`, `format`, `clean`, `outdated`, `upgrade` →
  `configuration`; `build`, `run` → `build`; `format-check`, `lint`,
  `typecheck`, `check` → `checks`; `test` → `tests`.
- `format` and `format-check` always also run `mise fmt` / `mise fmt --check`
  and `just --fmt` / `just --fmt --check`, so the project's own config files
  are held to the same gate.
- `outdated` never writes and tolerates the "updates found" non-zero exit via
  the `-` line prefix; `upgrade` masks nothing.
- `upgrade` deliberately uses `mise upgrade --local --bump --yes` (and, for
  TypeScript, `bun update --latest`). The `justfile` skill's default is
  range-preserving, but these pins are exact, so without `--bump` the recipe
  would be a no-op — this is a deliberate deviation from that skill's default,
  made because every tool this scaffold pins is pinned to an exact version.
- `clean` uses a fixed artifact list and no `git ls-files` guard, because the
  scaffold writes the matching `.gitignore` in the same run and every listed
  path is ignored. `deps` restores everything `clean` removes.
- No `[project.scripts]`-style indirection in recipes: write the real command
  a recipe needs directly, never a wrapper script the package manager exposes.

## Do NOT

- Hardcode a tool version anywhere in a scaffolded file. Every version comes
  from `mise use --pin <tool>@latest` at scaffold time.
- Use `npm run`/`bun run`/`uv run` *script* indirection in a recipe when the
  underlying command can be written directly in the justfile.
- Add a recipe for a tool the project does not install.
- Put a machine-wide package manager invocation in the project justfile —
  only project-scoped, mise-pinned tools belong there.
- Leave a `.python-version` file behind; `mise.toml` is the single source of
  the pinned interpreter.
