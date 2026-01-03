# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that serves as a cross-machine configuration sync system. The home directory (`/Users/phatblat`) is the git repository root, containing shell configurations, custom scripts, and development tools alongside standard macOS user directories.

### Key Directories

- **`.config/`** — Configuration for multiple shells and tools
  - `fish/` — Fish shell config (primary shell)
  - `nushell/` — Nushell config (actively being expanded)
  - `zed/` — Zed editor settings
  - `mise/config.toml` — Tool version manager configuration

- **`bin/`** — Custom utility scripts
  - Includes build helpers, git utilities, and IDE wrappers

- **`dev/`** — Development workspace organized by language/tool
  - `vim/` — Vim configurations and plugins
  - `go/`, `nix/`, `terraform/`, `gha/`, `tracing/` — Project directories
  - Each contains subdirectories for specific projects

- **`docs/`** — Documentation including `functions.md` (shell function inventory)

## Shell Configuration

### Fish Shell (Primary)

**Config Path:** `~/.config/fish/config.fish`

Fish is the primary shell with the most comprehensive function/alias coverage (~376 functions). Key characteristics:

- Modern syntax, incompatible with Bash/Zsh by design
- Functions stored in `~/.config/fish/functions/`
- Dramatically easier to remember than other shells

### Zsh (Legacy)

Functions still in `.zsh` files but **not actively maintained**. New functions target Fish exclusively.

### Nushell (In Development)

Actively being configured with growing function coverage. Provides modern, structured output.

### Bash (Minimal)

Only 2 basic aliases; not a focus.

## Development Tools & Versions

**Tool Management:** `mise` (replaces nvm, rbenv, pyenv, etc.)

**Global Tools Configured** (see `~/.config/mise/config.toml`):

- Node 24.11.1
- Python 3.14.2
- Ruby 3.4.7
- Go 1.25.5
- Rust (via rustup)
- Gradle 9.2.1
- Docker, Docker Compose
- Terraform, Packer
- Specialized tools: ast-grep, ripgrep, yq, actionlint

Set `MISE_PIN=1` in all shells to lock versions.

## Common Commands

### Building & Linting

**Using justfile** (`~/justfile`):

- `just` — List available recipes
- `just install` — Install mise tools globally
- `just upgrade` — Update tools
- `just format` — Format mise config, justfile, and Claude settings
- `just lint` — Check justfile and shell scripts
- `just lint-fix` — Format shell scripts with shfmt

### Shell Function Management

**IMPORTANT:** When creating, modifying, or deleting shell functions, always update `~/docs/functions.md`:

1. Add/remove/update the row in the functions table (sorted alphabetically)
2. Update the checkmarks for which shells implement it (nu, fish, zsh, bash)
3. Update the Summary statistics if shell counts change

The repository tracks 749 shell functions across 4 shells.

### Code Search

Use **`ast-grep` (sg)** for code search and modification, NOT grep/ripgrep/sed:

```bash
sg --pattern 'function_name' --lang fish
```

## Architecture & Code Patterns

### Shell Function Organization

**Fish Functions:** Each function is typically a separate file in `~/.config/fish/functions/`. Naming convention uses underscores for related groups (e.g., `git_*`, `docker_*`).

**Function Categories:** (See `functions.md`)

- Git workflows: 100+ functions (a*, c*, d*, g*, l*, s*, t\* aliases)
- Docker/Container management: 40+ functions
- Build systems: Gradle, Xcode, Carthage integration
- System utilities: Brew, macOS, file operations
- Development: iOS, Android, Xcode specific tooling

### Git Configuration

**GPG Signing:** Enabled. Global config at `~/.gitconfig` with email overrides in `~/.config/git/config`.

**Git Aliases:** Defined as Fish functions in `~/.config/fish/functions/`.

**Rerere Enabled:** Git rerere helps with conflict resolution.

### macOS Multi-Machine Sync

This repo is synced across multiple Macs. Challenges:

- Many git repos in subdirectories confuse some git apps
- Local-only git config in `~/.config/git/config` overrides `.gitconfig` user email
- Bootstrap script exists but outdated (not updated since Bash era)

## Editor Configuration

**Primary Editor:** Zed

**EditorConfig** (`~/.editorconfig`):

- Default: UTF-8, LF line endings, 2-space indent
- Java/Gradle: 4-space indent
- Markdown: No trailing space trimming (intentional)
- Makefile/plist: Tab indentation

**Zed Settings:**

- Rust analyzer with custom `CARGO_TARGET_DIR`
- analyzerTargetDir enabled
- Tab size: 2 spaces (hard tabs disabled)

## Code Quality Standards

### Git Workflow

- Conventional commits: `feat:`, `fix:`, etc. (imperative mood, present tense)
- No `--no-verify` flag usage; respect pre-commit hooks
- Feature branches: Topic-based naming (e.g., `ben/fix-thing`)
- Never force push to main/master
- GPG commit signing enabled

### When Hooks Fail

1. Read complete error output
2. Identify which tool failed and why
3. Explain the fix and work through systematically
4. Only commit after all hooks pass (never bypass)

## Project Context

**Language Focus:** Primarily shell scripting, with supporting Go, Ruby, Python, and Swift tooling.

**Primary Use Cases:**

- Cross-machine dotfile synchronization
- Git workflow automation
- macOS system management
- Development environment orchestration
- iOS/Android development tooling

## Communication Notes

- Address user as "phatblat"
- Teammates: both fallible, push back with evidence
- Prefer simple, maintainable solutions
- Match surrounding code style over guides
- Only change code directly related to current task
