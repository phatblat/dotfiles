#
# justfile for ~phatblat
#
# export - Export all variables as environment variables.

set export := true

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

alias fmt := format
alias ls := list
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

# Lists installed tools managed by mise
[group('info')]
list:
    mise list --global

# Lists available upgrades
[group('info')]
outdated:
    mise outdated --bump

# Search for a tool in mise or homebrew
[group('info')]
search tool:
    #!/usr/bin/env bash
    set -euo pipefail

    if mise search "{{ tool }}" &>/dev/null; then
        echo "Finding latest version of {{ tool }} in mise..."
        version=$(mise ls-remote "{{ tool }}" | tail -n1)
        echo -e "Latest version: {{ color_green }}{{ tool }}@$version{{ color_reset }}"
    elif brew search "{{ tool }}" | grep -q "{{ tool }}"; then
        echo "Tool '{{ tool }}' found in homebrew:"
        brew info "{{ tool }}"
    else
        echo "Tool '{{ tool }}' not found in mise or homebrew"
        exit 1
    fi

# Show Claude usage statistics
[group('info')]
usage:
    ccusage

# Show Claude usage statistics dashboard
[group('info')]
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

# Installs tools using mise
[group('configuration')]
install:
    mise install

# Installs Claude Code native binary
[group('configuration')]
install-claude:
    npx @anthropic-ai/claude-code install

# Upgrades tools using mise
[group('configuration')]
upgrade:
    claude update
    mise upgrade --bump

# Formats mise config, justfile, and Claude settings.json
[group('configuration')]
format:
    mise fmt
    just --fmt
    jq --sort-keys --indent 2 . ~/.claude/settings.json | sponge ~/.claude/settings.json
    jq --sort-keys --indent 2 . ~/.config/zed/settings.json | sponge ~/.config/zed/settings.json

# Removes default.store files, *.hprof files, and homebrew cache from home directory
[group('configuration')]
clean:
    rm -f "$HOME/Library/Application Support/default.store"*
    rm -f "$HOME"/*.hprof
    rm -rf "$(brew --cache)"

#
# checks group recipes
#

# Checks justfile and shell scripts in .config/zsh/functions
[group('checks')]
lint:
    mise fmt --check
    just --fmt --check
    @echo "Linting shell scripts..."
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' -exec shellcheck -s ksh -e SC2111 {} +

# Format shell scripts in .config/zsh/functions
[group('checks')]
lint-fix:
    @echo "Formatting shell scripts..."
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' -exec shfmt -w -i 4 -sr {} +
