# Nushell Migration Plan

Plan for porting actively-used zsh/fish shell functions to nushell.
Branch: `nushell-migration`. Machine-readable classification: [nushell-migration.json](nushell-migration.json).

Research method: usage-driven triage of 617 unported functions against fish history
(27k lines) and zsh history (1k lines), then per-function classification of all 129
used candidates by parallel agents, each adversarially verified by an independent
agent, plus a set-level completeness critic (dependency closure, doc drift,
triage blind spots, nu builtin collisions).

## Decisions (locked)

- **Scope**: usage-driven — port functions with recorded history usage plus their
  dependency closure. Defer the 488 zero-usage candidates.
- **Source of truth**: zsh implementation wins; fish fills gaps (zsh is the daily
  driver).
- **Done means**: nu parse check + smoke test + bats test in `~/tests/`,
  `just check` green.
- **Structure**: keep one-file-per-function in `~/.config/nushell/autoload/`,
  `export def` style, `^` for externals, `def --env` for cd/env mutation.
  No worktree (autoload must load from the live tree); work on this branch.

## Scope summary

| Bucket | Count | Notes |
| ------ | ----- | ----- |
| Wave 1 — trivial (alias/wrapper, difficulty 1) | 46 | Sonnet, candidates for Haiku after pilot |
| Wave 2 — logic / pipeline rewrites | 59 | Sonnet |
| Wave 3 — env-mutating / interactive / hard | 17 | Sonnet, includes all `def --env` |
| Wave 0 — shared helpers (dependency closure) | 6 | `error`, `edit`, `is_mac`, `is_linux`, `nav`, `rev-parse` |
| Cluster dependencies (port with their caller) | 25 | see Clusters below |
| Extra trivial alias (critic blind-spot find) | 1 | `pai` (zshrc alias) |
| **Total port units** | **154** | |
| Dropped (obsolete) | 4 | `as`, `fc`, `fl`, `jabba` (java is mise-managed) |
| Deferred (needs nu-native redesign) | 6 | `reload`, `fn`, `fe` + their private deps `yn`, `editw`, `function_template` |
| Already done | 1 | `wt-env` (verify, fix tracking row) |

## Renames (nu builtin collisions — verified on nu 0.113.1)

Only two names collide with nu builtins; everything else verified clean.

- `skip` → **`gskip`** — nu's `skip` is a core pipeline filter; shadowing it would
  break unrelated nu code. Ours is `git rebase/cherry-pick/am --skip`.
- `mkdir` → **`mkcd`** — nu's `mkdir` already creates intermediate dirs; the custom
  value is the trailing `cd`, which as a shadow would surprise every script.
  `mkcd` keeps the builtin intact.
- `error` → **`error-msg`** (found during wave 0) — `error` is a nu parser
  keyword (`error make`); a custom `def error` is ambiguous at call sites and
  fails to resolve in live sessions. Wave 2 callers (`maslink`, `sethostname`,
  `masrm`, `wip`) must call `error-msg`.

Record both renames in `docs/functions.md` notes.

## Wave 0 — hygiene + shared helpers (do first, single session)

1. Fix `docs/functions.md` drift found by the critic:
   - `github-pat-refresh` falsely marked nu ✅ (no file exists)
   - `cc` falsely marked ➖ (autoload/cc.nu exists)
   - duplicate conflicting `bD` rows (line ~77 stale, ~83 correct)
   - `ghostty.nu` exists but has no row
   - `wt-env` already implemented — remove from any port tracking
2. Configure zsh history persistence (`HISTFILE`/`HISTSIZE`/`SAVEHIST` are unset,
   so only 1k lines exist) — future triage rounds need real zsh data.
3. Port shared helpers used by multiple port targets: `error`, `edit`, `is_mac`,
   `is_linux`, `nav`, `rev-parse`. (`is_mac`/`is_linux` become thin wrappers over
   `$nu.os-info.name`.)
4. Establish the bats pattern for nu functions (first test file):
   `run nu --no-config-file -c "source '$HOME/.config/nushell/autoload/<fn>.nu'; <fn> ..."`
5. Config-level parity items (not function ports):
   - `_set_tab_title` zsh precmd hook → nu `pre_prompt` hook in config.nu
   - fish vi-mode → verify `$env.config.edit_mode = 'vi'`
   - fish Alt-, / Alt-z keybindings (`__prev_token`, `__re_extension`) →
     reedline keybindings; optional, decide during wave 0
   - `col1` and the fish `sort` wrapper are subsumed by nu structured data —
     mark n/a in functions.md, do not port

## Waves 1–3 — parallel porting (Workflow fan-out)

Function lists live in [nushell-migration.json](nushell-migration.json)
(`wave` field). Clusters must land in one batch with their caller:

| Caller | Rides along |
| ------ | ----------- |
| `jdk` | `jdk_set`, `jdk_current`, `path_add` |
| `bundle-pull` | `git_bundle_create`, `git_inside_repo`, `git_repo_dirty`, `repeatchar`, `current_branch` |
| `ddc` | `dcp`, `dip`, `dnp`, `dvp` |
| `masd` | `clone_or_pull`, `createdirs` |
| `upstall` | `⏫_upstall` (the 3.5K real implementation behind the shim) |
| `shell_choose` | `shell_add`, `shell_switch` |
| `xcswitch` | `xcss` |
| `masrm` | `fileowner` |
| `sshkeyfingerprint` | `sshkey` |
| `xcvall` | `pkginfo` |
| `ip` | `en1` |
| `cdown` | `curl_download` |
| `untar` | `file_base` (or inline `path parse | get stem`) |
| `wip` | `git_repo_clean` |
| `ap` | `toggle_wait` (same wave, same batch) |

### Orchestration design

- **Mechanism**: Workflow tool (scripted fan-out over subagents) — not agent
  teams. Intermediate results stay in script variables, schema-validated output
  retries automatically, and the merge phase is deterministic.
- **Batching**: ~8–12 functions per agent, grouped by wave + category so each
  batch owns a disjoint set of `autoload/*.nu` files and one batch-owned test
  file `tests/nu-<category>.bats`. Workers never touch shared files.
- **Pilot**: the first wave-1 batch (10 git/brew wrappers) runs alone to
  calibrate the recipe, test pattern, and pass rate before fanning out.
- **Models**: Sonnet implements; verification is deterministic-first (parse +
  smoke + bats exit codes), then an independent Sonnet reviewer checks semantic
  parity against the zsh/fish source (no self-grading). Consider Haiku for
  remaining wave-1 batches only if the pilot pass rate is high.
- **Single-writer aggregation**: after each wave, one agent updates
  `docs/functions.md` statuses from the workers' structured results.
- **Gate per wave**: `just check` must pass; commit per wave via `/git:commit`
  (logical grouping), push to remote.

### Dependency documentation (required in every ported file)

Every ported `.nu` file starts with a dependency comment block, then a blank
line, then the normal description docstring above the `def` (so nu help text
stays clean):

```nu
# Dependencies:
#   functions: error nav      <- custom functions/aliases called (or "none")
#   builtins:  glob input     <- nu builtins doing real work, or shadowed (or "none")
#   externals: git fzf        <- external binaries invoked (or "none")

# Short description of what the command does
export def foo [] { ... }
```

Reviewers verify the block exists and matches the actual body.

### Porting recipe (worker decision tree)

1. Pure prefix expansion, no logic → `export alias name = ^cmd args`
2. Single external call, args appended → `export def name [...args] { ^cmd ...$args }`
3. Forwards arbitrary unknown flags → `export def --wrapped name [...rest] { ^cmd ...$rest }`
4. Contains `cd`/`pushd`/`export` that must persist → `export def --env`
5. `||` fallback chains → nested `try/catch` (non-zero exit codes throw since nu 0.98)
6. grep/awk/sed/while-read pipelines → rewrite natively (`lines`, `where`,
   `split column`, `str replace`); insert `to text` before piping tables to externals
7. String interpolation: `"${var}"` → `$"($var)"`; bare `$var` does not interpolate
8. Globs must be explicit: `glob "*.sh"`, never bare strings
9. Parse gate: `nu --no-config-file -c "source <file>"` (exits 1 on error;
   do NOT use `--ide-check`, it always exits 0)
10. Anything needing zsh/fish machinery (`autoload`, `$functions`, `funced`,
    rc sourcing) → report SKIP with reason, do not guess

Per-function gotchas (verifier-checked) are in the manifest `notes` field —
workers must read them.

## Verification protocol

1. Parse: `nu --no-config-file -c "source <file>"` exits 0
2. Smoke: invoke read-only functions with safe args (source callee files first
   for cross-function deps)
3. Bats: one test per function in the batch-owned `tests/nu-<category>.bats`
4. Independent semantic review: separate agent diffs nu behavior vs zsh source
5. Wave gate: `just check` green before commit

## Follow-ups (wave 3 session)

- `pp.nu` inlines push logic (ported before `publish` existed) — refactor to
  call `publish` and update its dependency block.
- `cc.nu` (pre-migration port) uses plain rest params; make it `--wrapped` so
  `ccc`/`ccr` can call `cc --continue`/`cc --resume` like the zsh originals.
- `bq` API changed: nu parses `--` itself, so the zsh `bq <formula> -- <filter>`
  became `bq <formula> --filter <expr>` (default `.`).
- `upstreamify`'s bats test stubs `rv` — unstub now that `rv.nu` is fixed.

## Deferred / dropped detail

- **Dropped**: `as` (Android Studio opener, obsolete), `fc`+`fl` (obsolete,
  `fc` is also a zsh builtin name so usage counts were inflated), `jabba`
  (java now managed by mise). Remove their functions.md rows.
- **Deferred**: `reload`, `fn`, `fe` — these manipulate the *defining shell's*
  function machinery; a nu equivalent is a redesign (re-source module files),
  not a port. Revisit after the waves land. Their private helpers `yn`,
  `editw`, `function_template` defer with them.
- **Deferred long tail**: 488 unused candidates — reassess once zsh history
  has accumulated (wave 0 item 2).
