# phatblat's dotfiles

Shell setup and customization along with various system and app configuration files.

I regularly switch between several Macs and use this repo to sync terminal and some GUI app configurations across them. Many Stack Overflow answers (usually reworked a bit) have landed here over the years.

This repo lives at the root of my user `$HOME` dir. This confuses some git apps like Tower because I have lots of git repos in subdirectories. But, I prefer to see the dirty and upstream marker changes in the terminal prompt when I'm sitting in my home dir. Otherwise, I forget to commit, push or pull changes.

**Nested repos:** `dev/` and similar workspace directories contain separate git repos that are not part of this one — run git commands from `~` (or with `-C ~`) when you mean to operate on dotfiles.

## Shells

I started tracking these dotfiles when I was still using Bash, moved to [Z shell](http://zsh.sourceforge.net), then added [Fish](https://fishshell.com) for its friendlier syntax. These days I'm migrating toward [Nushell](https://www.nushell.sh) for its structured data pipelines, while keeping Zsh, Fish, and Bash working.

Functions are mirrored across shells (using each shell's own idioms rather than a literal translation) rather than kept in just one. For the current state of each shell's role and the full function inventory, see `docs/functions.md`. Shell config lives under `.config/zsh/`, `.config/fish/`, `.config/nushell/`, and `.bashrc`.

## Everyday commands

Common tasks (installing tools, linting, testing, formatting) are wired up as [`just`](https://github.com/casey/just) recipes. Run `just --list` for the full set, or see `CLAUDE.md` for the ones used most often.

## Package management

CLI tools are installed primarily through [mise](https://mise.jdx.dev), with Homebrew as a fallback and a separate, intentionally-unsynced Nix/home-manager experiment. See `docs/package-management.md` for the strategy and drift-checking tooling.

## Multi-tool parity

Shells, package managers, and AI coding agent harnesses (Claude Code, Codex, and others configured here) are three separate places where "mostly the same setup" needs to be kept from silently drifting apart, each with a different strategy and level of automation. See `docs/tooling-dimensions.md` for the overview.

## Git

[`.gitconfig`](https://github.com/phatblat/dotfiles/blob/main/.gitconfig) is checked in but I use different `user.email` values on my work and personal Macs. This is accomplished by setting local-only values in the alternate user-global [`~/.config/git/config`](http://git-scm.com/docs/git-config#FILES), but is overridden on an as-needed basis by explicitly setting `user.email` in some repos.

I've crafted a slew of short functions/aliases for all the git commands I use regularly, implemented across the shells above. There's even a `bundle-pull` function for quickly syncing a dirty work tree from one Mac to another.

## iOS

There are some shell functions for easily inspecting, bumping version and releasing an app with a versioned Xcode project.

## AI coding agents

This repo also configures several AI coding agent harnesses (Claude Code, Codex, and others) with shared instructions, commands, skills, and safety hooks under `.agents/harness/`. See `docs/agent-harnesses.md` for what's kept in parity across harnesses and what's harness-specific.

## Credit

Inspired by https://github.com/rtomayko/dotfiles

## License

This repo is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for rights and limitations.
