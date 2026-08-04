# OMP Agent YAML Formatting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Normalize `~/.omp/agent/config.yml` with the existing Prettier YAML formatter while preserving its complete settings mapping.

**Architecture:** This is a scoped, in-place formatting operation on OMP's required YAML global settings file. Prettier 3.9.6 parses and rewrites the one explicit path; a Ruby standard-library YAML comparison proves the pre- and post-format mappings are identical. The formatting operation must preserve user changes detected during planning.

**Tech Stack:** Prettier 3.9.6, YAML, Ruby standard library, Git.

---

## Scope and decisions

- Modify only `~/.omp/agent/config.yml`; it must remain YAML because OMP does not support TOML for this global settings file.
- Use the repository's pinned Prettier binary and target the explicit file. Do not add a formatter, change a formatter configuration, or format a directory.
- The current file has concurrent semantic edits relative to the branch. Treat those edits as user work: preserve them exactly and do not include them in an automated commit.
- Do not run repository-wide lint or tests. Prettier's YAML parse/check plus a structural YAML equality check are the relevant behavioral verification.

## File structure

| Path | Responsibility |
| --- | --- |
| `~/.omp/agent/config.yml` | OMP's global, YAML-formatted agent settings; the only file formatted. |
| `docs/superpowers/specs/2026-08-04-omp-agent-yaml-formatting-design.md` | Approved design record; no implementation change. |

### Task 1: Format and structurally verify OMP settings

**Files:**
- Modify: `~/.omp/agent/config.yml`
- Create temporarily: a `mktemp` backup outside the repository; remove it after verification

- [ ] **Step 1: Re-read the current configuration and its working-tree diff**

Run:

```sh
git -C ~ diff -- .omp/agent/config.yml
sed -n '1,220p' ~/.omp/agent/config.yml
```

Expected: any current model-role or other semantic changes are visible and are
preserved. Stop if the file is missing or no longer contains a YAML mapping.

- [ ] **Step 2: Make a protected pre-format snapshot**

Run:

```sh
config="$HOME/.omp/agent/config.yml"
backup="$(mktemp "${TMPDIR:-/tmp}/omp-agent-config.yml.XXXXXX")"
cp -p "$config" "$backup"
printf '%s\n' "$backup"
```

Expected: the printed temporary path contains an exact copy of the current
configuration, including concurrent user changes.

- [ ] **Step 3: Apply the scoped YAML formatter**

Run:

```sh
prettier --write "$HOME/.omp/agent/config.yml"
```

Expected: Prettier reports that it formatted exactly that YAML file. If it
reports a parse error, restore the backup with `cp -p "$backup" "$config"` and
stop.

- [ ] **Step 4: Verify parseability, formatting convergence, and semantic equality**

Run:

```sh
config="$HOME/.omp/agent/config.yml"
prettier --check "$config"
ruby -ryaml -e '
  before = YAML.safe_load(File.read(ARGV.fetch(0)), aliases: true)
  after = YAML.safe_load(File.read(ARGV.fetch(1)), aliases: true)
  abort "OMP settings mapping changed" unless before.is_a?(Hash) && before == after
' "$backup" "$config"
```

Expected: Prettier reports the file is formatted, and Ruby exits `0`. A nonzero
result means restore `"$backup"` before further work.

- [ ] **Step 5: Inspect the final diff, retain the backup until accepted, and do not auto-commit**

Run:

```sh
git -C ~ diff --check -- .omp/agent/config.yml
git -C ~ diff -- .omp/agent/config.yml
```

Expected: no whitespace errors; the diff represents formatting plus the
pre-existing user changes. Do not stage or commit this mixed diff. After the
user accepts the resulting config state, remove the temporary backup with
`rm "$backup"`; commit only a user-approved, correctly scoped change.
