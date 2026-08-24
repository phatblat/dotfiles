# omp Extension Configuration and Discovery

How omp finds extension/hook modules, in what order, and how to turn them off.
Source: `omp://extension-loading.md` (see also `omp://config-usage.md` for the
wider settings surface).

## Discovery inputs, in load order

`discoverAndLoadExtensions()` builds one ordered list, then loads it.

### 1. Native auto-discovered modules

| Scope | Path |
|---|---|
| Project | `<cwd>/.omp/extensions` |
| User | active agent directory's `extensions/` (default `~/.omp/agent/extensions`) |
| Legacy JSON lists | `<cwd>/.omp/settings.json#extensions`, agent dir `settings.json#extensions` |

The project root is the native provider's `.omp` directory — **cwd-only, it does
not walk ancestors**. Native auto-discovery is `.omp` based; legacy `.pi` is
still accepted in package manifests (`pi.extensions`) and project override
lookup, but `.pi/extensions` is not a native root.

### 2. Discovered JS/TS hook factories

Any hook-capability entry whose path is `.ts`/`.js` loads through the same
module pipeline. These already apply their own hook-specific disabled ids, so
they are **not** additionally filtered by `disabledExtensions` extension-module
names.

### 3. Installed plugin extension entries

From enabled installed plugins via `getAllPluginExtensionPaths(cwd)`, declared
in package `omp.extensions` / `pi.extensions` manifests, including enabled
feature entries.

### 4. Explicitly configured paths

In this order:

1. CLI paths — `--extension`/`-e`, and `--hook` (treated as an extension path)
2. Merged settings `extensions` array

## Deduplication

Absolute-path based, **first seen wins**, later duplicates ignored.

Implication: a module that is both auto-discovered and explicitly configured
loads once, at the auto-discovered position — not where you configured it.

## Settings files

| Scope | File |
|---|---|
| User | active agent dir `config.yml` — default `~/.omp/agent/config.yml` |
| User (profile) | `~/.omp/profiles/<name>/agent/config.yml` under `omp --profile <name>` |
| Project | `<cwd>/.omp/config.yml` and `<cwd>/.omp/settings.json` |
| Legacy JSON | agent dir `settings.json`, `<cwd>/.omp/settings.json` |

`PI_CODING_AGENT_DIR` overrides the agent directory, which moves both the
`config.yml` location and the native `extensions/` root.

```yaml
# ~/.omp/agent/config.yml
extensions:
  - ~/my-exts/safety.ts
  - ./local/ext-pack
```

```json
{ "extensions": ["./.omp/extensions/my-extra"] }
```

## Disabling

### All discovery

- CLI: `--no-extensions`
- SDK: `disableExtensionDiscovery`

Both keep the explicit-only contract: `-e/--extension` and `--hook` paths still
load. Under the CLI flag, only sibling capability roots from explicitly named
extension packages stay eligible — project/user `extensions:` settings and
installed OMP extension packages are excluded.

This governs extension factories and OMP extension-package sibling roots only.
It is **not** a whole-process capability switch: skills, MCP servers, tools,
prompts, and rules keep their own controls.

### One module

`disabledExtensions` filters by capability id. For extension modules the id is
`extension-module:<derivedName>`, where `derivedName` comes from the entry path:

| Entry path | Derived name |
|---|---|
| `/x/foo.ts` | `foo` |
| `/x/bar/index.ts` | `bar` |

```yaml
disabledExtensions:
  - extension-module:foo
```

### Items of other capabilities

Every capability defining `toExtensionId` contributes to the same list. Context
files use `context-file:<level>:<basename>` with `<level>` of `user` or
`project`:

```yaml
disabledExtensions:
  - context-file:user:CLAUDE.md
```

That id carries no directory and no depth, so a `project` entry disables files
of that name at **every depth** the discovery walk reaches.

## Path and entry resolution

Configured paths are normalized: Unicode spaces and shorthands (`file://`,
`@/absolute/path`, a stray `:` before a path), `~` expansion, then resolved
against `cwd` if relative. The internal `local://` scheme is rejected — it must
go through its protocol handler.

**Path is a file** — used directly. `.ts`, `.js`, `.mjs`, `.cjs` all supported.

**Path is a directory** — resolution order:

1. `package.json` with `omp.extensions` (or legacy `pi.extensions`) → declared entries
2. `index.ts`
3. `index.js`
4. Otherwise scan **one level**: direct `*.ts`/`*.js`, subdir `index.ts`/`index.js`,
   subdir `package.json` with `omp.extensions`/`pi.extensions`

Rules:

- No recursion beyond one subdirectory level.
- Manifest entries resolve relative to the package directory, and are included
  only if the file exists and is accessible.
- In `*/index.{ts,js}` pairs, TypeScript wins.
- Symlinks are eligible.

### Suffix support differs by source

| Source | Suffixes |
|---|---|
| Native + configured-directory auto-scan | `.ts`, `.js` |
| Explicit named files, installed-plugin manifest entries | `.ts`, `.js`, `.mjs`, `.cjs` |

### Gitignore applies unevenly

- Native auto-discovery: native glob, `gitignore: true`, `hidden: false`.
- Explicit configured-directory scanning in `loader.ts`: plain `readdir`, **no
  gitignore filtering**.

A module ignored by git still loads if you point at its directory explicitly.

## Module import contract

Each candidate loads via `loadLegacyPiModule()`:

- entry realpath resolved, dynamically imported with an `?mtime` cache-buster so
  edited source reloads
- a scoped Bun `onLoad` hook rewrites legacy pi-package specifiers
  (`@mariozechner/*`, `@earendil-works/*`) and bare `@sinclair/typebox` onto the
  host-bundled copies before evaluation
- factory selected by `getExtensionFactory(module)` — the module itself if it is
  a function, else `module.default`
- factory must be a function; may return `void` or a promise, which is awaited
  before the next path loads

A non-function export fails that path with a structured error; loading
continues.

## Failure and isolation

Per-path load failures are captured as `{ path, error }` and do not stop other
paths. Common causes: import failure, missing file, non-function export, or a
throw during factory execution.

At runtime, extensions are **not sandboxed** — same process, one shared
`EventBus`, one `ExtensionRuntime`. During load, action methods deliberately
throw `ExtensionRuntimeNotInitializedError`; wiring happens in
`ExtensionRunner.initialize()`. After load, handler exceptions are caught and
surfaced as extension errors rather than crashing the runner loop — except
`emitToolCall`, which propagates and blocks the tool.

## Layout examples

User level:

```text
~/.omp/agent/
  config.yml
  extensions/
    guardrails.ts
    audit/
      index.ts
```

Project level:

```text
<repo>/
  .omp/
    settings.json
    extensions/
      checks/
        package.json
      lint-gates.ts
```

`checks/package.json`:

```json
{ "omp": { "extensions": ["./src/check-a.ts", "./src/check-b.js"] } }
```
