#
# justfile for ~phatblat
#
# export - Export all variables as environment variables.

set export := true

export MISE_PIN := "1"

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
# color_gray := '\e[90m'
# color_red := '\e[31m'

color_green := '\e[32m'
color_reset := '\e[0m'

#
# aliases
#

alias dashboard := gt-dashboard-open
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
upgrade *args:
    mise upgrade --bump {{ args }}

# Upgrades each outdated tool and commits the version change individually
[group('configuration')]
upgrade-commits:
    #!/usr/bin/env bash
    set -euo pipefail
    json=$(mise outdated --bump --json)
    if echo "$json" | jq -e 'type == "object" and (keys | length) == 0' >/dev/null 2>&1; then
        echo "All tools are up to date"
        exit 0
    fi
    echo "$json" | jq -r 'keys[]' | while read -r tool; do
        current=$(echo "$json" | jq -r --arg t "$tool" '.[$t].current')
        bump=$(echo "$json" | jq -r --arg t "$tool" '.[$t].bump')
        echo "Upgrading $tool: $current → $bump"
        mise upgrade --bump "$tool"
        git add ~/.config/mise/config.toml
        git commit -m "chore: bump $tool $current → $bump"
    done

# Updates home-manager flake and rebuilds configuration
[group('configuration')]
update-nix:
    sudo determinate-nixd upgrade
    determinate-nixd status
    nix flake update --flake ~/.config/home-manager
    home-manager switch --flake ~/.config/home-manager

# Removes default.store files, *.hprof files, and homebrew cache from home directory
[group('configuration')]
clean:
    trash $(mise cache)
    mise prune
    brew cleanup
    rm -f "$HOME/Library/Application Support/default.store"*
    rm -f $HOME/*.hprof
    rm -f $HOME/.claude.json.backup.*
    rm -rf "$(brew --cache)"

#
# checks group recipes
#

# Runs system diagnostics using mise and homebrew
[group('checks')]
doctor:
    mise doctor
    brew doctor
    claude doctor
    claudekit doctor

# Checks .gitignore is correctly sorted with negation overrides intact
[group('checks')]
lint-gitignore:
    ~/scripts/sort-gitignore < ~/.gitignore | diff --brief - ~/.gitignore

# Lints Python scripts with ruff
[group('checks')]
lint-python:
    ruff check ~/scripts/sort-tools.py

# Lints Zsh functions with shellcheck

# Uses ksh dialect and excludes SC2168 (local in function body) since these are zsh autoload files
[group('checks')]
lint-zsh:
    @echo "Linting Zsh functions..."
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' -exec shellcheck -s ksh -e SC2168 {} +

# Validates Fish functions syntax
[group('checks')]
lint-fish:
    @echo "Validating Fish functions..."
    @fish -n ~/.config/fish/config.fish
    @find ~/.config/fish/functions -name '*.fish' -exec fish -n {} +
    @find ~/.config/fish/conf.d -name '*.fish' -exec fish -n {} +

# Validates Nushell scripts syntax
[group('checks')]
lint-nushell:
    @echo "Validating Nushell scripts..."
    @nu --commands 'source ~/.config/nushell/config.nu'

# Lints bin scripts with shellcheck (excludes vendor scripts)
[group('checks')]
lint-bin:
    @echo "Linting bin scripts..."
    @find ~/bin -name '*.sh' ! -name 'dotnet-install.sh' -exec shellcheck {} +

# Runs all linting checks
[group('checks')]
lint-all: lint-zsh lint-fish lint-nushell lint-bin
    @echo "All linting complete"

# Checks justfile and mise config formatting, gitignore, python, and shell scripts
[group('checks')]
lint: lint-gitignore lint-python lint-all
    just --fmt --check
    mise fmt --check

# Runs bats tests
[group('tests')]
[script]
test:
    echo "Running tests..."
    eval "$(mise activate bash)"
    bats ~/tests/

# Sorts .gitignore with negation-aware ordering
[group('configuration')]
format-gitignore:
    ~/scripts/sort-gitignore < ~/.gitignore | sponge ~/.gitignore

# Formats and sorts mise config
[group('configuration')]
format-mise:
    #!/usr/bin/env bash
    set -euo pipefail
    mise fmt
    # Sort [tools] entries alphabetically while preserving the rest of the file
    python3 ~/scripts/sort-tools.py

# Formats mise config, justfile, Claude settings.json and shell scripts
[group('configuration')]
format: format-gitignore format-mise
    just --fmt
    jq --sort-keys --indent 2 . ~/.claude/settings.json | sponge ~/.claude/settings.json
    jq --sort-keys --indent 2 . ~/.config/zed/settings.json | sponge ~/.config/zed/settings.json
    jq --sort-keys --indent 2 . ~/Library/Application\ Support/Claude/claude_desktop_config.json | sponge ~/Library/Application\ Support/Claude/claude_desktop_config.json
    jq --sort-keys --indent 2 . ~/.codexbar/config.json | sponge ~/.codexbar/config.json
    @echo "Formatting shell scripts..."
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' -exec shfmt -w -i 4 -sr {} +
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' -exec shellharden --replace {} +

#
# git group recipes
#

# Installs git hooks from tracked directory
[group('git')]
git-hooks:
    git config --local core.hooksPath .config/git/hooks
    @echo "Git hooks installed from .config/git/hooks/"

#
# claude group recipes
#

# Installs Claude Code native binary
[group('claude')]
install-claude:
    npx @anthropic-ai/claude-code install

alias uc := upgrade-claude

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
# gastown group recipes
#

# Start the Gastown dashboard web server
[group('gastown')]
gt-dashboard-start:
    #!/usr/bin/env bash
    if lsof -iTCP:8080 -sTCP:LISTEN -t &>/dev/null; then
        echo "Dashboard already running on port 8080"
    else
        cd ~/gt && gt dashboard --port 8080 &
    fi

# Stop the Gastown dashboard web server
[group('gastown')]
gt-dashboard-stop:
    -pkill -f 'gt dashboard'

# Open the Gastown dashboard in browser
[group('gastown')]
gt-dashboard-open: gt-dashboard-start
    open http://localhost:8080

# Start and attach to the Mayor session
[group('gastown')]
gt-mayor:
    cd ~/gt && gt mayor status 2>&1 | grep -q "is running" || gt mayor start --agent codex
    cd ~/gt && gt mayor attach

# Open the Gastown feed TUI
[group('gastown')]
gt-feed:
    cd ~/gt && gt feed

# Create and sling one polecat per outdated mise tool bump
[group('gastown')]
gt-mise-bump-polecats rig='dotfiles':
    ~/scripts/gt-mise-bump-polecats --all --rig {{ rig }}

# Dry-run preview of all outdated mise tool bump dispatches
[group('gastown')]
gt-mise-bump-polecats-dry-run rig='dotfiles':
    ~/scripts/gt-mise-bump-polecats --all --rig {{ rig }} --dry-run

# Create and sling a single tool bump to one polecat
[group('gastown')]
gt-mise-bump-polecat tool current bump rig='dotfiles':
    ~/scripts/gt-mise-bump-polecats \
        --tool {{ tool }} \
        --current {{ current }} \
        --bump {{ bump }} \
        --rig {{ rig }}

# Apply low-risk rig role-agent policy (witness/refinery -> gemini)
[group('gastown')]
gt-agent-policy-apply:
    ~/scripts/gt-agent-policy-apply apply

# Show current low-risk rig role-agent policy
[group('gastown')]
gt-agent-policy-show:
    ~/scripts/gt-agent-policy-apply show

# Smart sling wrapper: auto-route low-risk work to gemini, high-risk to codex
[group('gastown')]
gt-sling-smart bead target *args:
    ~/scripts/gt-sling-smart {{ bead }} {{ target }} {{ args }}

# Preview smart sling routing decision without dispatching
[group('gastown')]
gt-sling-smart-dry-run bead target *args:
    ~/scripts/gt-sling-smart {{ bead }} {{ target }} {{ args }} --dry-run

#
# lm-studio group recipes
#

# Start LM Studio server
[group('lm-studio')]
lms-start:
    lms server start

# Stop LM Studio server
[group('lm-studio')]
lms-stop:
    lms server stop

# Reload model
[group('lm-studio')]
lms-reload:
    lms unload qwen/qwen3-coder-480b
    lms load qwen/qwen3-coder-480b \
        --context-length 65536 --gpu max -y
    lms ls
    lms ps
    lms server status

# gastown group recipes

# Attach to the Gas Town mayor tmux session
[group('gastown')]
mayor:
    cd ~/gt && gt mayor attach
