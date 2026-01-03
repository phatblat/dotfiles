# Package Management

This document describes the package management strategy for this dotfiles repository.

## Overview

Package management uses a hybrid approach:
- **Nix home-manager** for CLI tools and cross-platform GUI apps
- **Homebrew** for macOS-specific GUI apps (casks)

## Nix Home-Manager

Configuration files:
- `~/.config/home-manager/flake.nix` - Flake configuration with nixpkgs input
- `~/.config/home-manager/home.nix` - Package list and home-manager settings

### Applying Changes

```bash
home-manager switch --flake ~/.config/home-manager#phatblat
```

### CLI Tools (54 packages)

All CLI tools are managed via home-manager:

| Package | Description |
|---------|-------------|
| act | Run GitHub Actions locally |
| apktool | Android APK reverse engineering |
| aria2 | Download utility |
| awscli2 | AWS CLI |
| bat | Cat clone with syntax highlighting |
| bazelisk | Bazel version manager |
| btop | Resource monitor |
| caddy | Web server |
| cmake | Build system |
| cocoapods | iOS dependency manager |
| delta | Git diff viewer |
| direnv | Directory-specific env vars |
| fish | Fish shell |
| fswatch | File change monitor |
| fzf | Fuzzy finder |
| gh | GitHub CLI |
| git | Version control |
| git-lfs | Git Large File Storage |
| git-subrepo | Git subrepo support |
| gnumake | Make build tool |
| gnupg | GPG encryption |
| imagemagick | Image manipulation |
| jdt-language-server | Java language server |
| jujutsu | Git-compatible VCS |
| just | Command runner |
| kotlin-language-server | Kotlin language server |
| lazygit | Git TUI |
| llvmPackages.llvm | LLVM toolchain |
| mas | Mac App Store CLI |
| mise | Tool version manager |
| mkcert | Local TLS certificates |
| neovim | Text editor |
| nextdns | DNS privacy |
| nushell | Nu shell |
| omnisharp-roslyn | C# language server |
| openjdk17 | Java 17 |
| pnpm | Node package manager |
| protobuf | Protocol buffers |
| ripgrep | Fast grep |
| solargraph | Ruby language server |
| speedtest-cli | Network speed test |
| starship | Shell prompt |
| swig | Interface generator |
| tart | macOS VMs |
| todoist | Task manager CLI |
| tree | Directory tree |
| xcbeautify | Xcode log formatter |
| xcodes | Xcode version manager |
| zig | Zig compiler |
| zoxide | Smart cd |
| zsh | Zsh shell |

### GUI Apps (3 packages)

Developer tools that build from source and work well on macOS:

| Package | Location |
|---------|----------|
| wezterm | `~/Applications/Home Manager Apps/WezTerm.app` |
| zed-editor | `~/Applications/Home Manager Apps/Zed.app` |
| tart | `~/Applications/Home Manager Apps/tart.app` |

### Broken Packages

Some packages are marked as broken in nixpkgs:
- `calibre` - Use Homebrew cask instead

## Homebrew

Homebrew manages macOS GUI applications that require:
- Code signing
- Licensing/activation
- Deep macOS integration
- Proprietary distribution

### Casks (37 packages)

```
1password          jetbrains-toolbox  onedrive
arc                kaleidoscope       parallels
calibre            keycastr           rapidapi
chatgpt            kobo               readdle-spark
claude             linear-linear      slack
docker-desktop     lm-studio          steam
google-drive       logi-options+      tailscale-app
istat-menus        logitech-options   todoist-app
                   loom               tower
                   microsoft-teams    vysor
                   moom               warp
                   notion             whatsapp
                   notion-calendar    windows-app
                   obsidian           xcodes-app
                                      zoom
```

### Managing Casks

```bash
# List installed casks
brew list --cask

# Install a cask
brew install --cask <name>

# Update casks
brew upgrade --cask

# Uninstall a cask
brew uninstall --cask <name>
```

## Migration History

On 2026-01-03, packages were migrated from Homebrew to Nix:
- 54 CLI formulae moved to home-manager
- 3 GUI apps (wezterm, zed, tart) moved to home-manager
- 60 Homebrew dependencies auto-removed
- ~3.5GB disk space freed from Homebrew

## Decision Criteria

**Use Nix home-manager for:**
- CLI tools
- Cross-platform developer tools
- Open source apps that build from source

**Use Homebrew for:**
- Proprietary macOS apps
- Apps requiring code signing
- Apps with licensing/activation
- Apps not available or broken in nixpkgs
