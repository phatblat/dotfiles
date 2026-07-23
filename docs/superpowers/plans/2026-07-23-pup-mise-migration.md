# Pup mise Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install Pup 1.6.6 through mise, verify it works, then remove the Homebrew-managed Pup installation and declarations.

**Architecture:** mise's `github:` backend owns the pinned Pup binary using the upstream `DataDog/pup` release. Homebrew remains in place until the mise binary passes direct and fresh-shell verification, after which the formula, tap, and trust declaration are removed.

**Tech Stack:** mise, GitHub releases, Homebrew, TOML, JSON, Just, Bats

## Global Constraints

- Pin Pup to exactly version `1.6.6`.
- Do not remove Homebrew Pup until the mise-managed binary reports version `1.6.6`.
- Preserve Pup configuration, OAuth sessions, and macOS Keychain items.
- Keep mise tools alphabetically sorted.
- Use the repository's `git-commit` skill for commits and include the required Codex co-author trailer.

---

### Task 1: Migrate Pup from Homebrew to mise

**Files:**

- Modify: `.config/mise/config.toml:22-27`
- Modify: `Brewfile:4`
- Modify: `Brewfile:72`
- Modify: `.config/homebrew/trust.json:8`

**Interfaces:**

- Consumes: the upstream `DataDog/pup` GitHub release tagged `v1.6.6`
- Produces: a mise-managed `pup` executable reporting `pup 1.6.6`

- [ ] **Step 1: Confirm the migration preconditions**

Run:

```bash
git status --short
brew list --versions datadog-labs/pack/pup
mise ls-remote github:DataDog/pup | rg '^1\.6\.6$'
```

Expected:

- Git status is clean.
- Homebrew reports `pup 1.6.6`.
- mise reports `1.6.6` as an available release.

- [ ] **Step 2: Declare Pup in mise**

Add this entry after `"github:nushell/nushell"` in
`.config/mise/config.toml`:

```toml
"github:DataDog/pup" = "1.6.6"
```

Then normalize the mise configuration:

```bash
just format-mise
mise fmt --check
```

Expected: both commands exit successfully and the GitHub-backed tools remain
alphabetically sorted.

- [ ] **Step 3: Install and verify Pup through mise**

Run:

```bash
mise install github:DataDog/pup@1.6.6
mise which pup
mise exec github:DataDog/pup@1.6.6 -- pup --version
```

Expected:

- `mise install` succeeds.
- `mise which pup` resolves under `~/.local/share/mise/installs/`.
- The direct mise execution prints `pup 1.6.6`.

If any command fails, remove the unverified mise entry, run
`just format-mise`, and stop. Leave the Homebrew installation, `Brewfile`, and
Homebrew trust configuration unchanged.

- [ ] **Step 4: Remove the verified Homebrew installation**

Only after Step 3 succeeds, run:

```bash
brew uninstall datadog-labs/pack/pup
brew untap datadog-labs/pack
```

Expected: Pup is uninstalled from Homebrew and the now-unused tap is removed.
Do not delete `~/.config/pup` or any Keychain entries.

- [ ] **Step 5: Remove obsolete Homebrew declarations**

Delete these exact lines from `Brewfile`:

```ruby
tap "datadog-labs/pack"
brew "datadog-labs/pack/pup"
```

Delete this exact entry from `.config/homebrew/trust.json`:

```json
"datadog-labs/pack/pup",
```

Run:

```bash
just format-json
```

Expected: the JSON remains valid and sorted.

- [ ] **Step 6: Verify the final runtime and package-manager state**

Run:

```bash
zsh -lic 'command -v pup && pup --version'
mise which pup
if brew list --formula pup >/dev/null 2>&1; then exit 1; fi
if brew tap | rg -q '^datadog-labs/pack$'; then exit 1; fi
if rg -n 'datadog-labs/pack|brew "[^"]*pup"' Brewfile .config/homebrew/trust.json; then exit 1; fi
just package-audit
```

Expected:

- The login shell resolves Pup through mise and prints `pup 1.6.6`.
- `mise which pup` points into mise's installation root.
- Homebrew no longer lists the formula or tap.
- No Pup Homebrew declarations remain.
- The package audit does not report Pup as duplicated.

- [ ] **Step 7: Roll back if post-removal verification failed**

Skip this step when Step 6 passes. If Step 6 fails after Homebrew Pup was
removed:

1. Remove the mise declaration and restore these Homebrew declarations:

   ```ruby
   tap "datadog-labs/pack"
   brew "datadog-labs/pack/pup"
   ```

   ```json
   "datadog-labs/pack/pup",
   ```

2. Restore the live Homebrew installation:

   ```bash
   brew tap datadog-labs/pack
   brew install datadog-labs/pack/pup
   mise uninstall github:DataDog/pup@1.6.6
   just format-mise
   just format-json
   zsh -lic 'command -v pup && pup --version'
   ```

Expected: the login shell again resolves a working Homebrew Pup 1.6.6. Stop
after rollback and report the mise verification failure without committing the
migration.

- [ ] **Step 8: Run repository quality gates**

Run:

```bash
just format
just lint
just test
git diff --check
```

Expected: all commands pass.

- [ ] **Step 9: Commit and push the migration**

Stage only the migration files:

```bash
git add .config/mise/config.toml Brewfile .config/homebrew/trust.json
git diff --cached --check
```

Invoke the repository's `$git-commit` skill. The expected Conventional Commit
subject is:

```text
chore(mise): Manage Pup with mise
```

Push `thursday`, then verify:

```bash
git push
git status --short --branch
```

Expected: the branch is clean and synchronized with
`phatblat/thursday`.
