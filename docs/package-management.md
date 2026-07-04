# Package Management

This document describes the package management strategy for this dotfiles repository.

## Strategy

Three package managers are in play, with distinct roles rather than equal footing:

1. **mise (primary)** — the default for installing and version-pinning CLI tools. Prefer
   `mise search`/`mise use` for anything mise can provide, including via its `aqua:`,
   `cargo:`, `github:`, `npm:`, and `pipx:` generic backends when a tool isn't in the
   curated registry.
2. **Homebrew (fallback)** — used when mise genuinely can't provide a tool: macOS GUI
   apps (casks), formulae with no mise backend and no usable upstream release artifact
   (e.g. shell-script tools like `git-subrepo`), and licensed/signed software.
3. **Nix / home-manager (experiment)** — a separate, self-contained package set. It does
   **not** need to mirror mise or Homebrew, and drift between Nix and the other two is
   expected and fine. Treat it as an ongoing experiment, not a tier to keep in sync.

See `~/CLAUDE.md` ("Tool installation priority") for the concrete install-order checklist
used when adding a new tool.

## Keeping mise and Homebrew from drifting

The common failure mode is a tool ending up installed via both mise and Homebrew — usually
because a brew formula was installed standalone, or pulled in transitively as another
formula's dependency, and never removed after the same tool was added to mise.

Run the audit script to find these:

```bash
just package-audit
```

This compares mise's declared `[tools]` against Homebrew's *installed* formulae/casks
(not just `~/Brewfile`), so it also catches untracked stray installs. It's a basic,
name-based check — see the script's docstring (`scripts/audit-package-managers.py`) for
its known limitations (e.g. it won't catch a mise tool whose binary name differs from
the package name, like `jujutsu` providing `jj`).

`just package-audit` is informational only (not part of `just check`) since it depends on
live, machine-specific Homebrew/mise state rather than repo-tracked files.

## Homebrew

`~/Brewfile` tracks explicitly-declared taps, formulae, and casks. Manage it with:

```bash
brew bundle install       # or: just deps
brew bundle dump --force  # regenerate Brewfile from current installs (review the diff!)
```

Casks remain the primary use case — proprietary or code-signed macOS GUI apps that mise
and Nix can't install.

## Nix / home-manager

Configuration lives in `~/.config/home-manager/` (`flake.nix`, `home.nix`). Apply changes
with:

```bash
home-manager switch --flake ~/.config/home-manager#phatblat
```

Since this tier is intentionally not kept in sync with mise/Homebrew, there's no audit
tooling for it — check `home.nix` directly for its current package list.
