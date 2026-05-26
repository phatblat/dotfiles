---
description: Conventions for creating and editing justfiles
globs:
  - "**/justfile"
  - "**/*.just"
---

# Justfile Conventions

## Default Settings

Always include these settings at the top of every justfile:

```just
set export
set ignore-comments
set script-interpreter := ['bash', '-eu']
set quiet
set unstable
```

## Default Recipe

The `_default` recipe MUST be private (prefixed with `_`) and silent. It lists available recipes:

```just
[script]
_default:
    just --list
```

- Always name it `_default` (underscore prefix makes it unlisted)
- Use `[script]` attribute so the interpreter runs the body directly

## Recipe Organization

Only add groups when the justfile has **10 or more recipes** (excluding `_default`). Smaller justfiles stay flat — no `[group()]` attributes, no comment blocks.

When grouping, use `[group('name')]` attributes and comment blocks to visually separate groups:

```just
#
# group-name group recipes
#

[group('group-name')]
recipe-name:
    command
```

## Build Lifecycle Recipes

Include these standard recipes as applicable to the project. Use conventional names and group them:

| Recipe    | Group           | Purpose                        |
|-----------|-----------------|--------------------------------|
| `clean`   | `configuration` | Remove build artifacts/caches  |
| `lint`    | `checks`        | Run linters and static checks  |
| `build`   | `build`         | Compile/build the project      |
| `test`    | `tests`         | Run test suite                 |
| `run`     | `build`         | Run the project                |
| `deps`    | `configuration` | Install dependencies/tools     |
| `format`  | `configuration` | Auto-format code and configs   |
| `deploy`  | `deploy`        | Deploy to target environment   |

## Rename Suggestions

When editing an existing justfile, check for and suggest renaming:

| Old Name   | New Name | Reason                                       |
|------------|----------|----------------------------------------------|
| `install`  | `deps`   | Clearer intent — installs deps, not the app  |

Only suggest during active edits to the file. Don't open PRs or make changes solely to rename.

## Recipe Style

- Use `[script]` attribute for multi-line bash recipes instead of line continuations
- Start script recipes with `set -euo pipefail`
- Use `#!/usr/bin/env bash` shebang only when overriding the default interpreter
- Add recipe parameters with descriptive names: `recipe-name param:`
- Use `*args` for variadic pass-through: `recipe-name *args:`
- Prefer `@` prefix on individual lines over `set quiet` per-recipe when only some lines should be silent
- Use aliases for common shortcuts: `alias f := full-recipe-name`

## Formatting

- Run `just --fmt` to auto-format (requires `set unstable`)
- Keep recipe comments on the line directly above the recipe (these become help text in `--list`)
- Use kebab-case for recipe names
