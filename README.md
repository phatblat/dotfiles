# phatblat's dotfiles

Shell setup and customization along with various system and app configuration files, synced across several macOS systems.

This repo lives at the root of `$HOME`, not in its own directory.

**Nested repos:** `dev/` and similar workspace directories contain separate git repos that are not part of this one — run git commands from `~` (or with `-C ~`) when you mean to operate on dotfiles.

## Shells

I started tracking these dotfiles when I was still using Bash, moved to [Z shell](http://zsh.sourceforge.net), then added [Fish](https://fishshell.com) for its friendlier syntax. These days I'm migrating toward [Nushell](https://www.nushell.sh) for its structured data pipelines, while keeping Zsh, Fish, and Bash working.

Functions are mirrored across shells (using each shell's own idioms rather than a literal translation) rather than kept in just one. For the current state of each shell's role and the full function inventory, see `docs/functions.md`. Shell config lives under `.config/zsh/`, `.config/fish/`, `.config/nushell/`, and `.bashrc`.

## Everyday commands

Common tasks (installing tools, linting, testing, formatting) are wired up as [`just`](https://github.com/casey/just) recipes. Run `just --list` for the full set, or see `CLAUDE.md` for the ones used most often.

## Package management

CLI tools are installed primarily through [mise](https://mise.jdx.dev), with Homebrew as a fallback and a separate, intentionally-unsynced Nix/home-manager experiment. See `docs/package-management.md` for the strategy and drift-checking tooling.

## Agent harness

This repo also configures several AI coding agent harnesses (Claude Code, Codex, and others) with shared instructions, commands, skills, and safety hooks under `.agents/harness/`. See `docs/agent-harnesses.md` for what's kept in parity across harnesses and what's harness-specific.

## Multi-tool parity

Shells, package managers, and AI coding agent harnesses (Claude Code, Codex, and others configured here) are three separate places where "mostly the same setup" needs to be kept from silently drifting apart, each with a different strategy and level of automation. See `docs/tooling-dimensions.md` for the overview.

## Credit

Inspired by https://github.com/rtomayko/dotfiles

## License

This repo is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for rights and limitations.
