#
# justfile for ~phatblat
#
# export - Export all variables as environment variables.

set export

export MISE_PIN := "1"
export PATH := env("HOME") / ".local" / "bin" + ":" + env("PATH")

# ignore-comments - Ignore comments when formatting.

set ignore-comments

# script-interpreter - Command used to invoke recipes with empty [script] attribute.

set script-interpreter := ['bash', '-eu']
set quiet

# unstable - Enable unstable features. Required for --fmt.

set unstable

#
# variables
#
# ANSI colors for formatting output
# color_gray := '\e[90m'
# color_red := '\e[31m'

color_green := '\e[32m'
color_reset := '\e[0m'

# Zsh functions excluded from shfmt (space-separated, use unsupported zsh-specific syntax like ${=VAR})

shfmt_exclude_functions := 'edit'

# Zsh functions excluded from shellharden (space-separated, rely on intentional word-splitting)

shellharden_exclude_functions := 'version_build version_market xccheck'

#
# aliases
#

alias f := free
alias fmt := format
alias i := deps
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

# Lists installed tools managed by uv
[group('info')]
list-uv:
    mise exec -- uv tool list

# Lists available upgrades
[group('info')]
outdated:
    mise outdated --bump

# Lists outdated uv tools
[group('info')]
outdated-uv:
    mise exec -- uv tool list --outdated

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
    just format

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

# Installs mise
[group('configuration')]
install-mise:
    curl https://mise.run | sh

# Installs Homebrew packages from Brewfile
[group('configuration')]
install-brew:
    brew bundle install

# Installs LaunchDaemons into /Library/LaunchDaemons (prompts for sudo)
[group('configuration')]
install-launchdaemons:
    ./scripts/install-launchdaemons

# Verifies GitHub auth/rate-limit before mise installs, so a silent 403 wall surfaces as a clear error
[group('configuration')]
[script]
_check-github-token:
    set -euo pipefail
    token="${MISE_GITHUB_TOKEN:-${GITHUB_TOKEN:-}}"
    auth=()
    [[ -n "$token" ]] && auth=(-H "Authorization: Bearer $token")
    json=$(curl -sS --max-time 10 "${auth[@]}" -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/rate_limit 2>/dev/null || true)
    # Offline / unreachable, or no python3 to parse: don't block local work.
    [[ -z "$json" ]] && exit 0
    command -v python3 >/dev/null 2>&1 || exit 0
    read -r limit remaining reset_at <<<"$(printf '%s' "$json" | python3 -c 'import sys,json; c=json.load(sys.stdin).get("resources",{}).get("core",{}); print(c.get("limit",0), c.get("remaining",0), c.get("reset",0))' 2>/dev/null || echo "0 0 0")"
    red=$'\033[31m'; yellow=$'\033[33m'; rc=$'\033[0m'
    when=$(date -r "$reset_at" '+%H:%M:%S' 2>/dev/null || echo '?')
    fix() {
        echo "  Re-authenticate, then sync the fresh token into ~/.env:" >&2
        echo "    gh auth refresh -h github.com -s repo,read:org" >&2
        echo "    TOKEN=\$(GITHUB_TOKEN= GITHUB_API_TOKEN= gh auth token)" >&2
        echo "    sed -i '' -E \"s|^(export (GITHUB_TOKEN|GITHUB_PERSONAL_ACCESS_TOKEN|MISE_GITHUB_TOKEN))=.*|\\1=\$TOKEN|\" ~/.env" >&2
        echo "    direnv reload" >&2
    }
    # limit <= 60 means GitHub is treating us as anonymous (no token, or token rejected).
    if (( limit <= 60 )); then
        if [[ -n "$token" ]]; then
            echo "${red}✗ GITHUB_TOKEN is set but GitHub is treating requests as unauthenticated (limit ${limit}/hr) — the token is being rejected.${rc}" >&2
            echo "${red}  mise will hit the ${limit} req/hr cap during install.${rc}" >&2
            echo "" >&2
            fix
            exit 1
        fi
        echo "${yellow}⚠ No GITHUB_TOKEN set — unauthenticated GitHub limit is ${limit}/hr. Set one in ~/.env to avoid install failures.${rc}" >&2
        exit 0
    fi
    # Authenticated tier, but the bucket is spent — mise install will 403 mid-run.
    if (( remaining == 0 )); then
        echo "${red}✗ GitHub API rate limit exhausted: 0/${limit} remaining (resets ${when}).${rc}" >&2
        echo "${red}  Wait for the reset, or mise install will fail with 403.${rc}" >&2
        exit 1
    fi
    if (( remaining < 100 )); then
        echo "${yellow}⚠ GitHub API rate limit low: ${remaining}/${limit} remaining (resets ${when}).${rc}" >&2
    fi

# Installs tools using mise
[group('configuration')]
deps: _check-github-token install-brew git-filters
    mise install

# Update tools within current versions
[group('configuration')]
update: update-rust

# Update Rust toolchains
[group('configuration')]
[script]
update-rust:
    set -euo pipefail
    rustup update

# Common upgrades
[group('configuration')]
upgrade: upgrade-mise upgrade-mise-tools-commit update-brew upgrade-brew upgrade-uv-tools

# Upgrades tools using mise
[group('configuration')]
upgrade-mise-tools *args:
    mise upgrade --bump --yes {{ args }}

# Upgrades mise itself
[group('configuration')]
upgrade-mise:
    mise self-update --yes

# Upgrades each outdated tool and commits the version change individually
[group('configuration')]
upgrade-mise-tools-commit:
    #!/usr/bin/env bash
    set -euo pipefail
    json=$(mise outdated --bump --json | jq 'with_entries(select(.value.bump | type == "string"))')
    if echo "$json" | jq -e 'type == "object" and (keys | length) == 0' >/dev/null 2>&1; then
        echo "All tools are up to date"
        exit 0
    fi
    echo "$json" | jq -r 'keys[]' | while read -r tool; do
        current=$(echo "$json" | jq -r --arg t "$tool" '.[$t].current')
        bump=$(echo "$json" | jq -r --arg t "$tool" '.[$t].bump')
        echo "Upgrading $tool: $current → $bump"
        mise upgrade --bump --yes "$tool"
        git add ~/.config/mise/config.toml
        git commit -m "chore: bump $tool $current → $bump"
    done

# Updates homebrew and lists outdated formulae/casks
[group('configuration')]
update-brew:
    brew update && brew outdated

# Upgrades homebrew formulae/casks (pass args through to brew upgrade)
[group('configuration')]
upgrade-brew *args:
    NONINTERACTIVE=1 brew upgrade {{ args }}

# Shows outdated uv-managed tools by comparing against PyPI
[group('configuration')]
outdated-uv-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    found=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[a-zA-Z] ]] || continue
        pkg=$(echo "$line" | awk '{print $1}')
        installed=$(echo "$line" | awk '{print $2}' | sed 's/^v//')
        latest=$(curl -sf "https://pypi.org/pypi/$pkg/json" | jq -r '.info.version' 2>/dev/null) || continue
        if [ "$installed" != "$latest" ]; then
            echo "$pkg $installed → $latest"
            found=1
        fi
    done < <(mise exec -- uv tool list)
    if [ "$found" -eq 0 ]; then
        echo "All uv tools are up to date"
    fi

# Upgrades all uv-managed tools
[group('configuration')]
upgrade-uv-tools:
    mise exec -- uv tool upgrade --all

# Updates home-manager flake and rebuilds configuration
[group('nix')]
update-nix:
    sudo determinate-nixd upgrade
    determinate-nixd status
    nix flake update --flake ~/.config/home-manager
    home-manager switch --flake ~/.config/home-manager

# Remove non-default Rust toolchains except stable and unpinned nightly
[group('configuration')]
[script]
clean-rust:
    set -euo pipefail
    in_section=false
    rustup show | while IFS= read -r line; do
        if [[ "$line" == "installed toolchains" ]]; then
            in_section=true
            continue
        fi
        if [[ "$line" == "active toolchain" ]]; then
            break
        fi
        if ! $in_section || [[ "$line" == -* ]] || [[ -z "$line" ]]; then
            continue
        fi
        toolchain="${line%% *}"
        if [[ "$line" == *"(default)"* ]] || [[ "$toolchain" == stable-* ]] || { [[ "$toolchain" == nightly-* ]] && [[ ! "$toolchain" =~ ^nightly-[0-9] ]]; }; then
            echo "keeping: $toolchain"
            continue
        fi
        echo "removing: $toolchain"
        rustup toolchain uninstall "$toolchain"
    done

# Removes default.store files, *.hprof files, zcompdump clutter, and homebrew cache from home directory
[group('configuration')]
clean:
    trash $(mise cache)
    mise cache clear --yes
    mise prune --yes
    brew cleanup
    rm -f "$HOME/Library/Application Support/default.store"*
    rm -f $HOME/*.hprof
    rm -f $HOME/.claude.json.backup.*
    rm -f $HOME/.zcompdump.DTO-*
    rm -rf "$(brew --cache)"
    if command -v nix >/dev/null 2>&1; then nix store gc; fi

#
# checks group recipes
#

# Runs system diagnostics using mise and homebrew
[group('checks')]
doctor:
    mise doctor
    brew doctor
    claude doctor

# Checks .gitignore is correctly sorted with negation overrides intact
[group('checks')]
lint-gitignore:
    ~/scripts/sort-gitignore < ~/.gitignore | diff --brief - ~/.gitignore

# Lints Python scripts with ruff
[group('checks')]
lint-python:
    @echo "Linting Python scripts..."
    ruff check ~/scripts/sort-tools.py ~/scripts/audit-package-managers.py ~/scripts/sort-codex-config.py ~/scripts/review-pr.py

# Checks the Codex config.toml is sorted (sections/keys alphabetized, state clustered)
[group('checks')]
lint-toml:
    python3 ~/scripts/sort-codex-config.py --check ~/.codex/config.toml

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

# Checks spelling with typos
[group('checks')]
check-spelling:
    mise exec -- typos

# Runs all linting checks
[group('checks')]
lint-all: lint-zsh lint-fish lint-nushell lint-bin
    @echo "All linting complete"

# Checks justfile and mise config formatting, gitignore, python, and shell scripts
[group('checks')]
lint: lint-gitignore lint-python lint-toml lint-all
    just --fmt --check
    mise fmt --check

# Runs lint, harness parity checks, and test
[group('checks')]
check: lint check-spelling harness-check test

# Generates shared/native agent harness parity artifacts
[group('checks')]
harness-generate:
    python3 ~/scripts/agent-harnesses.py generate

# Validates shared/native agent harness parity artifacts
[group('checks')]
harness-check:
    python3 ~/scripts/agent-harnesses.py validate

# Audits installed harness versions and parity gaps
[group('checks')]
harness-audit:
    python3 ~/scripts/agent-harnesses.py audit

# Flags CLI tools installed via both mise and Homebrew
[group('checks')]
package-audit:
    python3 ~/scripts/audit-package-managers.py

# Runs bats tests
[group('tests')]
[script]
test:
    echo "Running tests..."
    eval "$(mise activate bash)"
    [[ -d /nix/var/nix/profiles/default/bin ]] && export PATH="$PATH:/nix/var/nix/profiles/default/bin:${HOME}/.nix-profile/bin" || true
    bats ~/tests/

# Sorts .gitignore with negation-aware ordering
[group('configuration')]
format-gitignore:
    ~/scripts/sort-gitignore < ~/.gitignore | sponge ~/.gitignore

# Sorts the Codex config.toml (sections/keys alphabetized, machine state clustered)
[group('configuration')]
format-toml:
    python3 ~/scripts/sort-codex-config.py ~/.codex/config.toml

# Formats and sorts mise config
[group('configuration')]
format-mise:
    #!/usr/bin/env bash
    set -euo pipefail
    mise fmt
    # Sort [tools] entries alphabetically while preserving the rest of the file
    python3 ~/scripts/sort-tools.py

# Formats all tracked JSON/JSONC config files with sorted keys
[group('configuration')]
format-json:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ~
    git ls-files --cached '*.json' | while read -r f; do
        # vendored third-party gstack JSON — never reformat (churn / JSONC-truncation via jq|sponge)
        [[ "$f" == .claude/skills/gstack/* ]] && continue
        [[ "$f" == *.jsonc.json ]] && continue
        # Files that are actually JSONC despite .json extension
        case "$f" in
            .claude/policy-limits.json) continue ;;
            .config/zed/settings.json) continue ;;
            .config/cmux/cmux.json) continue ;;
            "Library/Application Support/Claude/claude_desktop_config.json") continue ;;
        esac
        printf '%s\0' "$f"
    # single process for all files — per-file jq|sponge spawns cost ~100ms each
    # under SentinelOne exec inspection, turning this loop into ~30s of waiting
    done | python3 ~/scripts/format-json.py
    jsonc_files=()
    while read -r f; do
        [[ "$f" == .claude/skills/gstack/* ]] && continue
        # opencode.jsonc is a generated artifact validated with strict json.loads
        # (no trailing commas) — prettier's jsonc parser adds them, so skip it.
        [[ "$f" == .config/opencode/opencode.jsonc ]] && continue
        jsonc_files+=("$f")
    done < <(git ls-files --cached '*.jsonc' '.config/zed/settings.json' '.config/cmux/cmux.json')
    # one prettier invocation — node startup pays the same per-exec toll
    if ((${#jsonc_files[@]})); then
        prettier --parser jsonc --write "${jsonc_files[@]}"
    fi

# Formats and hardens Zsh shell scripts
[group('configuration')]
format-shell:
    @echo "Formatting shell scripts..."
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' $(printf '! -name %s ' {{ shfmt_exclude_functions }}) -exec shfmt -ln zsh -w -i 4 -sr {} +
    @find ~/.config/zsh/functions -type f -name '*' ! -name '.*' $(printf '! -name %s ' {{ shellharden_exclude_functions }}) -exec shellharden --replace {} +

# Formats mise config, justfile, JSON/TOML configs, and shell scripts
[group('configuration')]
format: format-gitignore format-mise format-toml format-json format-shell
    just --fmt

#
# git group recipes
#

# Installs git hooks from tracked directory
[group('git')]
git-hooks:
    git config --local core.hooksPath .config/git/hooks
    @echo "Git hooks installed from .config/git/hooks/"

# Installs git clean filter that masks Codex config.toml churn (see .gitattributes)
[group('git')]
git-filters:
    git config --local filter.codex-config.clean ~/scripts/mask-codex-state.sh
    git config --local filter.codex-config.smudge cat
    git config --local filter.codex-config.required true
    @echo "Git filter 'codex-config' installed (masks ~/.codex/config.toml churn)"

#
# claude group recipes
#

# Builds the code-review-graph knowledge graph for the current repo
[group('claude')]
build-graph:
    code-review-graph build

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
# nix group recipes
#

# Installs Determinate Nix
[group('nix')]
install-nix:
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Restarts the Determinate Nix daemon
[group('nix')]
restart-nix:
    sudo launchctl kickstart -k system/systems.determinate.nix-daemon

# Uninstalls Determinate Nix
[group('nix')]
uninstall-nix:
    /nix/nix-installer uninstall

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
