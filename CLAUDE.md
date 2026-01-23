# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that serves as a cross-machine configuration sync system. The home directory (`/Users/phatblat`) is the git repository root, containing shell configurations, custom scripts, and development tools alongside standard macOS user directories.

### Key Directories

- **`.config/`** — Configuration for multiple shells and tools
  - `zsh/` — Zsh shell config (primary shell)
  - `fish/` — Fish shell config (secondary shell)
  - `nushell/` — Nushell config (actively being expanded)
  - `zed/` — Zed editor settings
  - `mise/config.toml` — Tool version manager configuration
  - `home-manager/` — Nix home-manager flake configuration

- **`bin/`** — Custom utility scripts (bash, shell, python, go)
  - Build helpers, git utilities, IDE wrappers

- **`dev/`** — Development workspace organized by language/framework
  - Projects grouped by topic: `_GETDITTO/`, `android/`, `apple/`, `flutter/`, `go/`, `terraform/`, `vim/`, etc.
  - Each contains subdirectories for specific projects

- **`docs/`** — Documentation
  - `functions.md` — Complete inventory of shell functions/aliases across all shells

## Shell Configuration Architecture

### Shell Priority & Maintenance

1. **Zsh (Primary)** — `~/.zshrc`
   - Functions in `~/.config/zsh/functions/*` (standalone autoload files)
   - Main shell for daily use, actively maintained
   - **ALWAYS use standalone autoload functions** — never define functions directly in `.zshrc`
   - All new functions target Zsh first
   - Uses Oh My Zsh with "clean" theme

2. **Fish (Secondary)** — `~/.config/fish/config.fish`
   - Functions in `~/.config/fish/functions/*.fish`
   - Modern syntax, incompatible with Bash/Zsh by design
   - Still maintained but no longer primary
   - Integrated with starship prompt, zoxide, fzf

3. **Nushell (Active Development)** — `~/.config/nushell/config.nu`
   - Actively being expanded
   - Provides modern, structured output
   - Functions defined in `~/.config/nushell/autoload/*.nu`

4. **Bash (Minimal)** — `~/.bashrc`
   - Basic aliases only, not a focus

### Shell Function Categories

Functions are organized by purpose (see `functions.md` for complete list):

- **Git workflows** — 100+ functions (short aliases: `a*`, `c*`, `d*`, `g*`, `l*`, `s*`, `t*`)
- **Docker/Container** — 40+ functions
- **Build systems** — Gradle, Xcode, Carthage, general build tooling
- **System utilities** — Brew, macOS system management, file operations
- **Development** — iOS, Android, Xcode, language-specific tooling

### Managing Shell Functions

**CRITICAL:** When creating, modifying, or deleting shell functions:

1. Update the function file in the appropriate shell directory (prioritize Zsh as primary shell)
   - **Zsh (PRIMARY):** ALWAYS create standalone files in `~/.config/zsh/functions/` (never define in `.zshrc`)
     - Start every file with `#!/usr/bin/env zsh` shebang
     - Add a comment describing the function (e.g., `# function_name - Description`)
     - **CRITICAL:** File content must be the function body directly, NOT wrapped in `function name() { }`
     - Zsh autoload expects the file content to BE the function body
     - Autoload files do NOT need execute permissions
     - Example:
       ```zsh
       #!/usr/bin/env zsh

       # aa - Add all modified tracked files to git staging area
       git add --update "$@"
       ```
   - **Fish:** Create standalone files in `~/.config/fish/functions/`
   - **Nushell:** Create standalone files in `~/.config/nushell/autoload/`
   - **Bash:** Define in `~/.bashrc`

2. **ALWAYS update `~/docs/functions.md`:**
   - Add/remove/update the row in the alphabetically-sorted table
   - Update checkmarks for which shells implement it (nu, fish, zsh, bash)
   - Update the Summary statistics if shell counts change

3. Test the function in the target shell

### Shell Function Overrides

Several common commands are overridden by Zsh functions:

- `cat` → wraps `bat` (modern cat replacement with syntax highlighting)
- `ls` → wraps `command ls -p` (adds trailing slashes on directories)

Use `command cat` or `command ls` to bypass these wrappers if needed.

## Development Tools & Versions

**Tool Management:**
- **`mise`** — Primary tool version manager (modern replacement for nvm, rbenv, pyenv, etc.)
- **Nix/home-manager** — System package management via flake at `~/.config/home-manager`

**Key Global Tools** (see `~/.config/mise/config.toml`):

- **Languages:** Node 25.3.0, Python 3.14.2, Ruby 3.4.8, Go 1.25.6, .NET 10.0.102
- **Build Systems:** Gradle 9.3.0, Just 1.46.0
- **Containers:** Docker CLI 29.1.5, Docker Compose 5.0.1
- **Infrastructure:** Terraform 1.14.3, Packer 1.14.3, gcloud 552.0.0
- **Specialized Tools:** ast-grep 0.40.3, ripgrep 15.1.0, fd 10.3.0, yq 4.50.1, actionlint 1.7.10, shellcheck 0.11.0, shfmt 3.12.0

**Version Locking:** Set `MISE_PIN=1` in all shells to lock tool versions (already configured in Fish and justfile).

## Common Commands

### Just Recipes

**Build & Management** (`~/justfile`):

- `just` or `just --list` — List all available recipes
- `just install` — Install all mise-managed tools globally
- `just upgrade [args]` — Upgrade tools and Claude Code, update Nix home-manager, commit mise config changes
- `just update-nix` — Update home-manager flake and rebuild configuration
- `just add <tool>` — Add and install latest version of a tool via mise
- `just remove <tool>` — Remove and uninstall a tool from mise
- `just search <tool>` — Search for a tool in mise or homebrew

**Info & Status:**

- `just list` (alias: `just ls`) — List installed mise tools
- `just list-missing` (alias: `just lsm`) — List missing mise tools
- `just list-nix` — List installed Nix packages
- `just outdated` (alias: `just od`) — List available tool upgrades
- `just free` (alias: `just f`) — Display free disk space on root drive

**Formatting & Linting:**

- `just format` (alias: `just fmt`) — Format mise config, justfile, Claude/Zed settings, and zsh shell scripts
- `just lint` — Check justfile, mise config, and shell scripts with shellcheck
- `just doctor` — Run mise and homebrew diagnostics

**Claude Code:**

- `just claude-continue` (alias: `just cc`) — Continue Claude session bypassing permissions
- `just usage` — Show Claude usage statistics
- `just usage-board` (alias: `just ub`) — Show live Claude usage dashboard
- `just usage-web` — Open Claude usage in browser
- `just install-claude` — Install Claude Code native binary
- `just upgrade-claude` — Upgrade Claude Code (also runs as part of `just upgrade`)

**Cleanup:**

- `just clean` — Remove default.store files, *.hprof files, and homebrew cache

### Code Search

Use **`ast-grep` (sg)** for code search and modification, NOT grep/ripgrep/sed:

```bash
sg --pattern 'function_name' --lang fish
```

## Git Configuration

**Commit Signing:** GPG signing enabled globally.

**Config Structure:**
- Global config: `~/.gitconfig` (tracked in repo)
- Local overrides: `~/.config/git/config` (not tracked, machine-specific user.email)
- Per-repo overrides: Can set `user.email` in individual repos as needed

**Git Aliases:** Defined as Fish functions in `~/.config/fish/functions/`, not in `.gitconfig`.

**Rerere:** Enabled for conflict resolution assistance.

**Hooks & Pre-commit:** Never bypass hooks with `--no-verify`. When hooks fail:
1. Read complete error output
2. Identify which tool failed and why
3. Fix the issue systematically
4. Only commit after all hooks pass

### Multi-Machine Sync Challenges

- Many git repos in subdirectories confuse some git apps (e.g., Tower)
- Local-only git config in `~/.config/git/config` overrides `.gitconfig` user email per machine
- Bootstrap script exists but outdated (not updated since Bash era)

## Editor Configuration

**Primary Editor:** Zed

**EditorConfig** (`~/.editorconfig`):

- **Default:** UTF-8, LF line endings, 2-space indent, trim trailing whitespace
- **Java/Gradle/Kotlin:** 4-space indent
- **Makefiles/plist/gitconfig:** Tab indentation
- **Markdown:** Trailing whitespace preserved (has meaning)
- **JSON:** Final newline ignored (inconsistent across tools)

**Zed Settings** (`~/.config/zed/settings.json`):

- Rust analyzer with custom `CARGO_TARGET_DIR`
- analyzerTargetDir enabled
- Tab size: 2 spaces (hard tabs disabled)

## Code Quality Standards

### Git Workflow

- **Conventional commits:** `feat:`, `fix:`, `docs:`, `chore:`, etc. (imperative mood, present tense)
- **Feature branches:** Topic-based naming (e.g., `ben/fix-authentication`)
- **Never force push** to main/master
- **GPG commit signing** enabled
- **No `--no-verify`** — Never bypass pre-commit hooks

### When Hooks Fail

1. Read complete error output
2. Identify which tool failed and why
3. Explain the fix and work through systematically
4. Only commit after all hooks pass (never bypass)

## Project Context

**Language Focus:** Primarily shell scripting (Zsh), with supporting tooling in Go, Ruby, Python, Swift, and other languages.

**Primary Use Cases:**

- Cross-machine dotfile synchronization
- Git workflow automation (100+ git-related functions)
- macOS system management
- Development environment orchestration
- iOS/Android development tooling
- Container and infrastructure management

## Development Workspace Organization

The `~/dev/` directory organizes projects by language, framework, or organization:

- `_GETDITTO/` — Work projects (Ditto)
- Language-specific: `go/`, `android/`, `apple/`, `flutter/`, `dotnet/`, `c/`
- Frameworks: `fastlane/`, `bazel/`, `ansible/`, `terraform/`
- Tools: `vim/`, `github/`, `buildkite/`
- Each contains subdirectories for specific projects

## Special Notes

- **timeout/gtimeout** not installed (use alternative timing methods)
- **ast-grep (sg)** is the primary code search/modification tool
- **bat** replaces cat in Zsh (syntax highlighting, git integration)
- **No trailing spaces** unless meaningful (e.g., Markdown line breaks)
- **Tool installation priority:**
  1. `mise search`/`mise use` for mise-managed tools
  2. `nix profile install nixpkgs#<package>` for Nix packages
  3. `brew search`/`brew install` as fallback
- **mise config location:** `~/.config/mise/config.toml`
- **Nix flake location:** `~/.config/home-manager`

## Communication Notes

- Address user as "phatblat"
- Teammates: both fallible, push back with evidence
- Prefer simple, maintainable solutions
- Match surrounding code style over style guides
- Only change code directly related to current task