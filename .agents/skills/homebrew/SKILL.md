---
name: homebrew
description: "Use when a project depends on Homebrew formulae or casks, when creating or editing a Brewfile, or when adding brew install/upgrade automation to a project."
---

# Homebrew Skill

Declare a project's Homebrew dependencies in a `Brewfile` and drive them with
`brew bundle`. This skill is the single source of truth for Homebrew
conventions across every coding agent; harness-specific rules load it rather
than repeating it.

## When to Use

- A project needs system-level tools that aren't available from its language
  package manager (`pkg-config`, `ffmpeg`, `postgresql`, a cask)
- A README or setup script tells contributors to run `brew install <x>`
- Adding install/upgrade automation for system dependencies
- Reviewing an existing `Brewfile` for convention drift

## Core Rule

**If a project uses Homebrew, its dependencies belong in a `Brewfile` — never
in loose `brew install` commands.** A `brew install foo bar baz` line in a
README, setup script, CI workflow, or justfile is undeclared state: nobody can
diff it, verify it, or remove it later. A `Brewfile` is a manifest, so it can
be reviewed, version-controlled, and checked.

Replace this:

```bash
brew install pkg-config ffmpeg
brew install --cask ngrok
```

With a `Brewfile`:

```ruby
brew "pkg-config"
brew "ffmpeg"
cask "ngrok"
```

## Process

### Step 1: Detect Homebrew Usage

Look for undeclared brew dependencies before assuming there are none:

```bash
ls Brewfile .Brewfile 2>/dev/null
grep -rn "brew install" --include=*.md --include=*.sh --include=*.yml . 2>/dev/null
```

If `brew install` appears anywhere but no `Brewfile` exists, that's the gap
this skill closes.

### Step 2: Write the Brewfile

Place `Brewfile` in the repository root. Entry types:

| Entry                        | Declares                          |
|------------------------------|-----------------------------------|
| `brew "name"`                | A formula (CLI tool, library)     |
| `cask "name"`                | A macOS application               |
| `tap "owner/repo"`           | A third-party tap                 |
| `mas "Name", id: 123`        | A Mac App Store app               |
| `vscode "publisher.ext"`     | A VS Code extension               |

Conventions:

- One dependency per line, grouped by type with `tap` first, then `brew`, then
  `cask`, then the rest. Keep each group alphabetized so diffs stay readable.
- Comment any entry whose purpose isn't obvious from its name — a bare
  `brew "pkg-config"` tells the next reader nothing about which build needs it.
- Declare only what the *project* needs. A contributor's personal tooling
  (shell, editor, fonts) belongs in their dotfiles Brewfile, not the repo's.
- Do not pin versions. Homebrew is a rolling-release package manager with no
  general version-pinning mechanism; `brew "node@20"` works only because a
  versioned formula happens to exist. If a project needs pinned tool versions,
  that's a job for `mise`, `asdf`, or the language's own toolchain file — not
  Homebrew.

### Step 3: Wire Up the Commands

| Intent                        | Command                                  |
|-------------------------------|------------------------------------------|
| Install declared deps         | `brew bundle install --no-upgrade`       |
| Upgrade declared deps         | `brew bundle upgrade`                    |
| Verify deps are satisfied     | `brew bundle check`                      |
| List declared deps            | `brew bundle list`                       |
| Snapshot installed → Brewfile | `brew bundle dump`                       |
| Remove undeclared packages    | `brew bundle cleanup`                    |

Three behaviors that are easy to get wrong:

- **`brew bundle install` upgrades by default.** Plain `brew bundle install`
  runs `brew upgrade` on anything outdated, so a command that reads like
  "install my dependencies" can silently move every version. Pass
  `--no-upgrade` whenever the intent is only "make sure these are present",
  and keep upgrading a separate, deliberate command. `brew bundle upgrade` is
  shorthand for `brew bundle install --upgrade`.
- **`brew bundle check` exits `1`** when a dependency is missing and `0` when
  everything is satisfied. That makes it a real CI gate — a non-zero exit here
  is a genuine failure, not just information.
- **`brew bundle cleanup` uninstalls.** It removes every Homebrew package not
  listed in the Brewfile, which on a developer's machine means their personal
  tools. Never run it against a project Brewfile on a shared or personal
  machine; it is only safe where the Brewfile is the complete intended state
  (a container, a CI runner, or a dotfiles repo).

### Step 4: Scope — Project vs. Global

`brew bundle` resolves its Brewfile in three ways. State the scope explicitly
rather than relying on "whatever is in the current directory":

| Scope   | Selector                       | Resolves to                                     |
|---------|--------------------------------|-------------------------------------------------|
| Project | `--file=Brewfile` (or default) | `./Brewfile` in the working directory           |
| Global  | `--global` / `-g`              | `$HOMEBREW_BUNDLE_FILE_GLOBAL`, else `$XDG_CONFIG_HOME/homebrew/Brewfile`, else `~/.homebrew/Brewfile` or `~/.Brewfile` |
| Custom  | `--file=<path>`                | That exact path                                 |

- **In a project repo**, target the project Brewfile. It declares what *this
  codebase* needs to build and test.
- **In a dotfiles repo**, `--global` is correct and intentional: it manages the
  machine's own baseline toolchain, which every directory then inherits.
- `HOMEBREW_BUNDLE_FILE` overrides the default path for every `brew bundle`
  invocation. It is convenient interactively and a trap in automation — a
  recipe that works on your machine breaks on a machine where that variable
  points somewhere else. In automation, pass `--file` explicitly.

### Step 5: `Brewfile.lock.json` Is Obsolete

Older Homebrew wrote a `Brewfile.lock.json` pinning resolved versions.
**Current Homebrew no longer generates it.** Verified on Homebrew 6.0.18:
`brew bundle install` produces no lockfile, and neither `brew bundle --help`
nor `brew bundle install --help` mentions locking at all.

So a `Brewfile.lock.json` sitting in a repo today is a frozen snapshot from an
older Homebrew that will never be refreshed again. It silently drifts from the
`Brewfile` as entries are added and removed, which makes it worse than absent:
a reader may reasonably assume it reflects current state.

When you find one:

- Confirm it is actually stale — compare its entry counts against the
  `Brewfile`, and check when git last touched each.
- If stale, delete it and gitignore the path. The `Brewfile` is the manifest;
  nothing reads the lockfile.
- Never hand-edit it, and never regenerate it by hand to "fix" the drift.
  There is no supported command that rewrites it.

Do not treat this as a reason to avoid Homebrew for reproducibility — it is a
rolling-release package manager and never offered real version pinning. If a
project needs reproducible tool versions, use `mise`, `asdf`, a container, or
Nix instead of trying to freeze Homebrew.

### Step 6: Verify

1. `brew bundle check --file=Brewfile` — confirms the Brewfile parses and
   reports what's missing (exit `1` if anything is).
2. `brew bundle list --file=Brewfile` — confirms every entry is recognized.
3. Report what was declared or changed.

## Integration with Just

When a project has both a `Brewfile` and a justfile, wire them together
following the `justfile` skill's lifecycle-recipe conventions:

```just
# Installs system dependencies from the Brewfile
[group('configuration')]
deps-brew:
    brew bundle install --file=Brewfile --no-upgrade

# Upgrades system dependencies declared in the Brewfile
[group('configuration')]
upgrade-brew:
    brew bundle upgrade --file=Brewfile

# Verifies declared system dependencies are installed
[group('checks')]
check-brew:
    brew bundle check --file=Brewfile
```

Homebrew has no `brew bundle outdated` subcommand. `brew outdated` reports
every outdated package on the machine, not just the project's, so it does not
belong in a project `outdated` recipe — see the `justfile` skill's rule against
machine-global package managers in project justfiles.

## Do NOT

- Leave `brew install` commands in a README, setup script, or CI workflow when
  a `Brewfile` could declare them.
- Run bare `brew bundle install` where the intent is install-only; it upgrades.
- Run `brew bundle cleanup` against a project Brewfile on a personal machine.
- Run machine-wide `brew upgrade` or `brew outdated` from a project justfile.
- Pin formula versions in a Brewfile; use a real version manager instead.
- Add a contributor's personal tooling to a project Brewfile.
- Hand-edit, regenerate, or trust a `Brewfile.lock.json`; current Homebrew no
  longer writes one, so any that exists is stale.
