# phatblat's dotfiles

This repository manages the shell environment, system configurations, and tool versions for a highly customized development setup across multiple Macs. It is maintained directly in the user's `$HOME` directory (`/Users/phatblat/`).

## Project Overview

- **Purpose:** Synchronize terminal and GUI app configurations, manage tool versions, and provide a productive development environment.
- **Primary Shell:** [Fish shell](https://fishshell.com) (configured in `~/.config/fish/`).
- **Secondary Shells:** Zsh (`~/.config/zsh/`) and Nushell (`~/.config/nushell/`).
- **Orchestration:** [just](https://github.com/casey/just) is used as the primary task runner for maintenance, installation, and information gathering.
- **Tool Management:**
    - **[mise](https://mise.jdx.dev/):** Manages versions for Go, Node.js, Python, Ruby, and many other CLI tools (configured in `~/.config/mise/config.toml`).
    - **[Homebrew](https://brew.sh/):** Manages system packages and GUI apps via `Brewfile`.
    - **[Nix](https://nixos.org/) & [home-manager](https://github.com/nix-community/home-manager):** Used for advanced, declarative configuration (configured in `~/.config/home-manager/`).

## Key Commands (via `just`)

The `justfile` in the root directory provides a wide range of utility recipes:

### Information & Diagnostics
- `just` (or `just list`): List all available recipes.
- `just doctor`: Run system diagnostics for `mise`, `brew`, and `claude`.
- `just list`: List all globally installed tools managed by `mise`.
- `just outdated`: List tools that have available upgrades.

### Configuration & Maintenance
- `just install`: Install tools defined in the `mise` configuration.
- `just upgrade`: Upgrade mise itself, update and upgrade Homebrew.
- `just clean`: Clean up caches (mise, brew) and temporary files.
- `just format`: Format configuration files (Zed, Claude) and shell scripts.

### Verification
- `just lint`: Run all linting checks (Python, Zsh, Fish, Nushell, bin scripts, and `.gitignore`).
- `just test`: Run automated tests using [bats](https://github.com/bats-core/bats-core) located in `~/tests/`.

## Directory Structure

- `~/.config/`: Configuration files for most tools (Fish, Zsh, Zed, mise, home-manager, etc.).
- `~/scripts/`: Custom maintenance scripts (e.g., `sort-gitignore`, `sort-tools.py`).
- `~/bin/`: User-defined executable binaries.
- `~/tests/`: [bats](https://github.com/bats-core/bats-core) test suites for verifying shell functionality.
- `~/gt/`: Gastown development workspace.

## Development Conventions

- **Tool Pinning:** Critical tools are often pinned to specific versions in `~/.config/mise/config.toml`.
- **Linting:** Shell scripts and Python scripts are strictly linted using `shellcheck`, `shfmt`, `shellharden`, and `ruff`.
- **Testing:** New shell functions or significant script changes should be verified with `bats` tests in `~/tests/`.
- **Configuration Management:** Prefer adding new tools via `just add <tool>` to ensure they are tracked in the `mise` configuration.
- **Git State:** The repository is intentionally kept at the root of `$HOME` to ensure visibility of changes in the terminal prompt.
