#
# justfile for ~phatblat
#
# export - Export all variables as environment variables.

set export := true

MISE_PIN := "1"

# ignore-comments - Ignore comments when formatting.

set ignore-comments := true

# script-interpreter - Command used to invoke recipes with empty [script] attribute.

set script-interpreter := ['bash', '-eu']
set quiet := true

# unstable - Enable unstable features. Required for --fmt.

set unstable := true

#
# variables
#
# ANSI colors for formatting output

color_gray := '\e[90m'
color_green := '\e[32m'
color_red := '\e[31m'
color_reset := '\e[0m'

#
# aliases
#

alias cc := claude-continue
alias f := free
alias fmt := format
alias i := install
alias ls := list
alias lsm := list-missing
alias od := outdated
alias ub := usage-board
alias up := upgrade

#
# info group recipes
#

# Default recipe, lists available recipes
[script]
_default:
    just --list

# Display free space on root drive
[group('info')]
free:
    @df -h / | awk 'NR==2 {print "Free space on /: " $4 " (" $5 " used)"}'

# Lists installed tools managed by mise
[group('info')]
list:
    mise list --global

# Lists missing tools managed by mise
[group('info')]
list-missing:
    mise list --global --missing

# Lists available upgrades
[group('info')]
outdated:
    mise outdated --bump

# Lists installed Nix packages
[group('info')]
list-nix:
    #!/usr/bin/env bash
    nix-store -q --requisites ~/.nix-profile |
      xargs -I {} basename {} |
      sed 's/^[a-z0-9]\{32\}-//' |
      sed -E 's/-(lib|dev|bin|static|doc)$//' |
      sort -u |
      sed -E 's/^(.*)-([0-9].*)$/\1 \2/' |
      column -t

# Search for a tool in mise or homebrew
[group('info')]
search tool:
    #!/usr/bin/env bash
    set -euo pipefail

    if mise search --match-type equal "{{ tool }}" &>/dev/null 2>&1; then
        echo "Finding latest version of {{ tool }} in mise..."
        version=$(mise ls-remote "{{ tool }}" | tail -n1)
        echo -e "Latest version: {{ color_green }}{{ tool }}@$version{{ color_reset }}"
    elif brew search "{{ tool }}" 2>&1| grep -q "{{ tool }}"; then
        echo "Tool '{{ tool }}' found in homebrew:"
        brew info "{{ tool }}"
    else
        echo "Tool '{{ tool }}' not found in mise or homebrew"
        exit 1
    fi

#
# claude group recipes
#

# Continue Claude Code session bypassing permissions
[group('claude')]
claude-continue:
    claude --continue --permission-mode bypassPermissions

# Installs Claude Code native binary
[group('claude')]
install-claude:
    npx @anthropic-ai/claude-code install

# Upgrades Claude Code
[group('claude')]
upgrade-claude:
    claude update

# Show Claude usage statistics
[group('claude')]
usage:
    ccusage

# Open Claude usage online
[group('claude')]
usage-web:
    open https://claude.ai/settings/usage

# Show Claude usage statistics dashboard
[group('claude')]
usage-board:
    ccusage blocks --live

#
# configuration group recipes
#

# Adds a new tool using mise, installing the latest version
[group('configuration')]
add tool:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! mise search "{{ tool }}" &>/dev/null; then
        echo "Tool '{{ tool }}' not found in mise registries"
        exit 1
    fi

    echo "Finding latest version of {{ tool }}..."
    version=$(mise ls-remote "{{ tool }}" | tail -n1)

    if [ -z "$version" ]; then
        echo "Could not determine latest version of {{ tool }}"
        exit 1
    fi

    echo "Installing {{ tool }}@$version..."
    mise use "{{ tool }}@$version"

# Removes a tool from mise config and uninstalls it
[group('configuration')]
remove tool:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! mise list --global | grep -q "{{ tool }}"; then
        echo "Tool '{{ tool }}' is not installed via mise"
        exit 1
    fi

    # Only uninstall if there are actual versions installed
    if mise list "{{ tool }}" 2>/dev/null | grep -q "{{ tool }}"; then
        echo "Uninstalling {{ tool }}..."
        mise uninstall "{{ tool }}"
    fi

    echo "Removing {{ tool }} from mise config..."
    mise rm "{{ tool }}"

# Installs tools using mise
[group('configuration')]
install:
    mise install

# Upgrades tools using mise
[group('configuration')]
upgrade *args: update-nix
    mise upgrade --bump {{ args }}
    claude /git ~/.config/mise/config.toml

# Updates nixpkgs channel and rebuilds home-manager configuration
[group('claude')]
update-nix:
    nix-channel --update
    nix flake update --flake ~/.config/home-manager
    home-manager switch --flake ~/.config/home-manager

# Formats mise config, justfile Claude settings.json and shell scripts
[group('configuration')]
format:
    mise fmt
    just --fmt
    jq --sort-keys --indent 2 . ~/.claude/settings.json | sponge ~/.claude/settings.json
    jq --sort-keys --indent 2 . ~/.config/zed/settings.json | sponge ~/.config/zed/settings.json
    @echo "Formatting shell scripts..."
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' -exec shfmt -w -i 4 -sr {} +

# Removes default.store files, *.hprof files, and homebrew cache from home directory
[group('configuration')]
clean:
    rm -f "$HOME/Library/Application Support/default.store"*
    rm -f "$HOME"/*.hprof
    rm -rf "$(brew --cache)"

#
# checks group recipes
#

# Runs system diagnostics using mise and homebrew
[group('checks')]
doctor:
    mise doctor
    brew doctor

# Checks justfile and shell scripts in .config/zsh/functions
[group('checks')]
lint:
    just --fmt --check
    mise fmt --check
    @echo "Linting shell scripts..."
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' -exec shellcheck -s ksh -e SC2111 {} +
