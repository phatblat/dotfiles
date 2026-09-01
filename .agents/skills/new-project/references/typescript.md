# TypeScript (bun) Reference

## 1. Pin tools

```bash
mise use --pin bun@latest just@latest npm:prettier@latest
```

## 2. `mise.toml`

After the pin step, append the `[deps.bun]` and `[settings]` blocks:

```toml
[tools]
bun = "<pinned>"
just = "<pinned>"
"npm:prettier" = "<pinned>"

# `mise deps` runs `bun install` when package.json or bun.lock changes.
[deps.bun]

[settings]
# `[deps.*]` is experimental. Declaring it here means the project works without
# the developer's global mise config enabling it.
experimental = true
```

Then run `mise trust && mise fmt`.

## 3. Native init

1. `bun init --yes`
2. **Delete the `scripts` block from `package.json`** — the justfile is the
   task surface, so `bun run <script>` indirection must not exist. If the
   installed `bun` version wires a `scripts` entry that something else
   depends on (e.g. a `bunfig.toml` reference), keep `package.json` valid but
   still remove `scripts` — the justfile stays the only task surface.
3. Set `name`, `description`, `license: "MIT"`, and `author: "Ben Chatelain"`
   in `package.json`.

`just` spawns a plain `sh`, which does not carry mise activation. Route
mise-pinned CLIs (prettier) through `mise exec` in the justfile:

```just
mise := "mise exec --"
```

## 4. Test

`test/index.test.ts` — a real test of the generated entrypoint's exported
function. If `bun init` did not export one from `index.ts`, export one first
so there is something to assert.

## 5. `.gitignore`

```gitignore
node_modules/
dist/
.DS_Store
*.log
```

## 6. `justfile`

Same header and `_default` block as the Python template (see
`references/python.md`), plus the `mise :=` assignment above. 10 non-default
recipes, so grouping applies:

| Recipe | Group | Body |
|---|---|---|
| `deps` | configuration | `mise install` then `mise deps` |
| `format` | configuration | `{{ mise }} prettier --write .`, `mise fmt`, `just --fmt` |
| `clean` | configuration | `rm -rf node_modules` |
| `outdated` | configuration | `-mise outdated --local --bump`, `-bun outdated` |
| `upgrade` | configuration | `mise upgrade --local --bump --yes`, `bun update --latest` |
| `run` | build | `bun run src/index.ts` (path per `bun init`) |
| `format-check` | checks | `{{ mise }} prettier --check .`, `mise fmt --check`, `just --fmt --check` |
| `typecheck` | checks | `bun x tsc --noEmit` |
| `check` | checks | `check: format-check typecheck test` |
| `test` | tests | `bun test` |

No `lint` recipe: bun ships no linter and this scaffold installs none, so per
the `justfile` skill's "don't add recipes for tools the project doesn't use"
rule, `check` is `format-check typecheck test` — no `lint` in the dependency
list. If a project later adds a linter, wire it into both a new `lint` recipe
and into `check`'s dependency list.

Full file:

```just
set ignore-comments
set script-interpreter := ['bash', '-eu']
set unstable

mise := "mise exec --"

[default]
_default:
    @just --list

#
# configuration group recipes
#

# Install pinned tools and dependencies
[group('configuration')]
deps:
    mise install
    mise deps

# Format source, mise config, and the justfile
[group('configuration')]
format:
    {{ mise }} prettier --write .
    mise fmt
    just --fmt

# Remove installed dependencies
[group('configuration')]
clean:
    rm -rf node_modules

# Report tools and dependencies with newer versions available
[group('configuration')]
outdated:
    -mise outdated --local --bump
    -bun outdated

# Upgrade pinned tools and dependencies to their latest versions
[group('configuration')]
upgrade:
    mise upgrade --local --bump --yes
    bun update --latest

#
# build group recipes
#

# Run the application
[group('build')]
run:
    bun run src/index.ts

#
# checks group recipes
#

# Verify formatting without writing changes
[group('checks')]
format-check:
    {{ mise }} prettier --check .
    mise fmt --check
    just --fmt --check

# Type-check with tsc
[group('checks')]
typecheck:
    bun x tsc --noEmit

# Run every gate: formatting, types, tests
[group('checks')]
check: format-check typecheck test

#
# tests group recipes
#

# Run the test suite
[group('tests')]
test:
    bun test
```
