# OpenAI Model Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Track the OpenAI GPT/Codex models available to this account in a committed lockfile, report unavailable configured models, and expose the catalog through `just` for Codex, Pi, and shared harness configuration.

**Architecture:** Add a provider-specific `scripts/openai-models.sh` alongside the existing Claude tracker. It will use OpenAI's documented `GET /v1/models` endpoint to write `.openai/models.lock` and validate model IDs referenced by tracked OpenAI-backed configuration. The tracker deliberately treats the live OpenAI API as authoritative only for API-key-backed IDs; Codex/ChatGPT-only model IDs remain catalog entries but are reported as unverified rather than falsely retired.

**Tech Stack:** Bash, curl, jq, Bats, just, OpenAI Models API.

---

## Scope and decisions

- Track only OpenAI-family IDs (`gpt-*`, `o*`, `codex-*`) in repository-owned configuration. Do not infer status for Claude, Cursor, Grok, Composer, or tier aliases such as `opus` and `sonnet`.
- Commit the lockfile at `.openai/models.lock`; do not commit runtime caches such as the untracked `.codex/models_cache.json`.
- Discover configured IDs from `.codex/config.toml`, `.pi/agent/settings.json`, `.pi/agent/agents`, `.agents`, and generated harness artifacts only when they contain explicit OpenAI model IDs. Exclude vendored/plugin caches and session data.
- Preserve the Claude tracker unchanged. A shared `just outdated-models` recipe will invoke each provider check independently and retain the current non-zero behavior only for a configured model that is definitively unavailable from its provider.
- Authentication order: `OPENAI_API_KEY` from the environment or `~/.env`; otherwise emit a successful, explicit skip. Do not read or expose Codex/ChatGPT OAuth credentials because they are not a supported substitute for the public Models API.
- The OpenAI API lists accessible API models but does not provide an equivalent model-retirement feed. The lockfile therefore records API availability and `created` epoch; it must not claim an API-absent Codex/ChatGPT-only model is retired.

## File structure

| Path | Responsibility |
| --- | --- |
| `scripts/openai-models.sh` | Fetch, normalize, render, and validate the OpenAI model catalog. |
| `.openai/models.lock` | Generated, committed snapshot of the accessible OpenAI Models API catalog. |
| `tests/openai-models.bats` | Mocked contract tests for lock generation, authentication skips, configured-ID classification, and drift. |
| `justfile` | List, refresh, and check recipes; integration into aggregate model maintenance. |
| `tests/justfile.bats` | Recipe-level test for printing OpenAI model IDs from the lockfile. |

### Task 1: Establish the lockfile contract with failing tests

**Files:**
- Create: `tests/openai-models.bats`
- Create later: `scripts/openai-models.sh`

- [ ] **Step 1: Write a lock-rendering test using a mocked Models API**

```bash
@test "openai-models: lock records sorted accessible GPT and Codex models" {
  local tmpdir="$BATS_TEST_TMPDIR/openai-lock"
  local bindir="$tmpdir/bin"
  local lockfile="$tmpdir/.openai/models.lock"
  mkdir -p "$bindir"

  cat >"$bindir/curl" <<'SH'
#!/usr/bin/env bash
printf '{"data":[{"id":"gpt-5.4","created":1780000000},{"id":"gpt-5.3-codex","created":1770000000},{"id":"text-embedding-3-large","created":1760000000}]}'
SH
  chmod +x "$bindir/curl"

  run env HOME="$tmpdir" PATH="$bindir:$PATH" OPENAI_API_KEY=test-key \
    OPENAI_MODELS_LOCK="$lockfile" "$HOME/scripts/openai-models.sh" lock

  [ "$status" -eq 0 ]
  run grep '^  ' "$lockfile"
  [ "$output" = $'  gpt-5.3-codex                 1770000000\n  gpt-5.4                       1780000000' ]
}
```

- [ ] **Step 2: Add failing tests for authentication and configured-model classification**

```bash
@test "openai-models: check skips successfully without an API key" {
  run env HOME="$BATS_TEST_TMPDIR/no-key" "$HOME/scripts/openai-models.sh" check
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipping live model check"* ]]
}

@test "openai-models: check fails only for configured API models absent from the catalog" {
  # Mock GET /v1/models with gpt-5.4 only, and a tracked config that names
  # gpt-5.4 plus gpt-removed. Assert status 1 and the gpt-removed diagnostic.
}
```

- [ ] **Step 3: Run the new test file and verify RED**

Run: `bats tests/openai-models.bats`

Expected: failure because `scripts/openai-models.sh` does not exist.

- [ ] **Step 4: Commit the test-only change**

```bash
git add tests/openai-models.bats
git commit -m "test(openai): Define model catalog contract"
```

### Task 2: Implement the OpenAI catalog tracker

**Files:**
- Create: `scripts/openai-models.sh`
- Test: `tests/openai-models.bats`

- [ ] **Step 1: Implement credential resolution and model fetching**

Implement the script with these constants and functions:

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly API="https://api.openai.com/v1/models"
readonly LOCKFILE="${OPENAI_MODELS_LOCK:-$HOME/.openai/models.lock}"

resolve_auth() {
  if [ -z "${OPENAI_API_KEY:-}" ] && [ -f "$HOME/.env" ]; then
    set -a
    . "$HOME/.env"
    set +a
  fi
  [ -n "${OPENAI_API_KEY:-}" ] || return 1
}

fetch_models() {
  curl -fsS --max-time 30 "$API" \
    -H "Authorization: Bearer $OPENAI_API_KEY" |
    jq -e '.data | map(select(.id | test("^(gpt-|o[0-9]|codex-)")))'
}
```

Do not print the authorization header or key in diagnostics. Treat HTTP errors as failures for `lock`; make the `check` path report a skipped live check only when no key is available.

- [ ] **Step 2: Implement deterministic lock rendering**

Render this format, sorted by model ID and using only stable API fields:

```text
# OpenAI model catalog — generated by scripts/openai-models.sh
# Source: GET /v1/models
# Regenerate: just update-openai-models
# generated: 2026-07-29
#
# id                           created
  gpt-5.4                       1780000000
```

Use `date -u +%Y-%m-%d` for the generated date and `jq -r '.[] | [.id, (.created // 0)] | @tsv' | sort` to produce rows. Create the parent directory before writing.

- [ ] **Step 3: Implement tracked-ID discovery and checking**

Add a `tracked_model_ids` function that uses `git -C "$HOME" grep --untracked` over only `.codex`, `.pi/agent`, `.agents`, and their generated harness artifacts; extract explicit values matching `gpt-[A-Za-z0-9.-]+`, `o[0-9][A-Za-z0-9.-]*`, or `codex-[A-Za-z0-9.-]+`; sort uniquely. Compare those IDs to the live API IDs.

Classify an API-absent configured ID as:

```text
  x <id> API model unavailable — referenced in tracked configuration
```

Exit 1 only for this classification. Add a documented allowlist/exception hook, `OPENAI_NON_API_MODELS`, for known ChatGPT/Codex-only IDs; print them as `unverified outside the public API` and do not fail.

- [ ] **Step 4: Run the tracker tests and verify GREEN**

Run: `bats tests/openai-models.bats`

Expected: all tests pass.

- [ ] **Step 5: Run ShellCheck and commit**

```bash
shellcheck scripts/openai-models.sh
bats tests/openai-models.bats
git add scripts/openai-models.sh tests/openai-models.bats
git commit -m "feat(openai): Track available models"
```

### Task 3: Add the initial catalog and just recipes

**Files:**
- Create: `.openai/models.lock`
- Modify: `justfile`
- Modify: `tests/justfile.bats`

- [ ] **Step 1: Write the failing just recipe test**

```bash
@test "list-openai-models prints lockfile model IDs" {
  local home="$BATS_TEST_TMPDIR/openai-home"
  mkdir -p "$home/.openai"
  printf '%s\n' '# OpenAI model catalog' '  gpt-5.4 1780000000' >"$home/.openai/models.lock"

  run env HOME="$home" just --justfile "$BATS_TEST_DIRNAME/../justfile" list-openai-models

  [ "$status" -eq 0 ]
  [ "$output" = "gpt-5.4" ]
}
```

- [ ] **Step 2: Run the focused recipe test and verify RED**

Run: `bats tests/justfile.bats`

Expected: the new test fails because `list-openai-models` is not defined.

- [ ] **Step 3: Add focused `just` recipes**

Add these recipes beside the Claude model recipes:

```just
[group('info')]
list-openai-models:
    awk '/^  (gpt-|o[0-9]|codex-)/{print $1}' ~/.openai/models.lock

[group('info')]
outdated-openai-models:
    scripts/openai-models.sh check

[group('configuration')]
[script]
update-openai-models:
    set -euo pipefail
    scripts/openai-models.sh lock
    git diff --quiet -- .openai/models.lock && { echo "OpenAI model catalog unchanged"; exit 0; }
    git add .openai/models.lock
    git commit -m "chore(openai): Refresh model catalog lockfile"
```

Update `outdated-models`, `update`, and `upgrade` to invoke both the Claude and OpenAI model recipes while preserving the existing recipe ordering.

- [ ] **Step 4: Generate the initial lockfile**

Run: `just update-openai-models`

Expected: `.openai/models.lock` is created and committed if `OPENAI_API_KEY` is available. If credentials are unavailable, leave the generated file creation blocked and document the exact command required; do not synthesize a catalog from `.codex/models_cache.json`.

- [ ] **Step 5: Verify and commit**

```bash
bats tests/justfile.bats
just --fmt --check
just list-openai-models
just lint
git add justfile tests/justfile.bats .openai/models.lock
git commit -m "feat(justfile): Manage OpenAI model catalog"
```

### Task 4: Validate cross-harness coverage and document the boundary

**Files:**
- Modify: `scripts/openai-models.sh`
- Modify: `tests/openai-models.bats`
- Modify: `docs/superpowers/plans/2026-07-29-openai-model-tracking.md` only if implementation decisions differ from this plan

- [ ] **Step 1: Add a regression fixture with representative Codex and Pi configuration**

Create temporary `.codex/config.toml` and `.pi/agent/settings.json` files containing `gpt-5.4`, `gpt-5.3-codex-spark`, and a non-OpenAI value. Assert that discovery includes only the two OpenAI IDs and that no session, cache, credential, or generated-model-store path is scanned.

- [ ] **Step 2: Add the ChatGPT/Codex-only exception regression test**

Mock an API response without `gpt-5.3-codex-spark`, set `OPENAI_NON_API_MODELS=gpt-5.3-codex-spark`, and assert status 0 plus `unverified outside the public API`. This prevents a Codex subscription model from being incorrectly reported as retired.

- [ ] **Step 3: Run complete verification**

```bash
bats tests/openai-models.bats tests/justfile.bats
just lint
just harness-check
```

Expected: all commands pass. Confirm `git diff --check` is clean and that the only generated artifact committed is `.openai/models.lock`.

- [ ] **Step 4: Commit the boundary tests and documentation**

```bash
git add scripts/openai-models.sh tests/openai-models.bats justfile tests/justfile.bats .openai/models.lock
git commit -m "test(openai): Cover harness model discovery"
```

## Self-review

- Coverage: Tasks 1–2 establish the provider tracker; Task 3 exposes refresh/check/list flows and seeds the committed catalog; Task 4 proves Codex/Pi discovery and protects the public-API versus ChatGPT/Codex boundary.
- No hidden credentials: tests mock `curl`; runtime only reads `OPENAI_API_KEY` through the established environment-file pattern and never logs it.
- No false retirement claim: API-only availability failures are distinct from explicit `OPENAI_NON_API_MODELS` exceptions.
- No provider scope creep: Claude behavior remains unchanged and non-OpenAI harness aliases are ignored.
