#
# justfile for ~phatblat
#

export PATH := env("HOME") / ".local" / "bin" + ":" + env("PATH")

# ignore-comments - Ignore comments when formatting.

set ignore-comments

# script-interpreter - Command used to invoke recipes with empty [script] attribute.

set script-interpreter := ['bash', '-eu']

# unstable - Enable unstable features.

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

# GitHub CLI extensions manifest file (one OWNER/REPO per line, read by install-gh-extensions)

gh_extensions_manifest := '.config/gh/extensions.txt'
# Tools excluded from `mise ... --bump` scans; each emits unfixable mise warnings and its
# bump is always null: wookie = rev-pinned cargo git ref (latest resolves to the ref string
# "HEAD"), dsh = prerelease-only npm package (mise resolves no "latest"), cursor-cli = http
# backend without version_list_url (cursor.com publishes no version feed).

mise_bump_exclusions := 'cargo:https://github.com/nkotval-ditto/wookie npm:@deepseek-ai/dsh http:cursor-cli'

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
[default]
_default:
    @just --list

# Display free space on the Data volume (~ resolves to it; / is the sealed, near-empty System volume)
[group('info')]
free:
    @avail=$(df -h ~ | awk 'NR==2 {print $4}'); df -Pk ~ | awk -v avail="$avail" 'NR==2 {printf "Free space: %s (%.0f%% available)\n", avail, 100 * $4 / ($3 + $4)}'
# Lists running sessions for the requested agent
[group('info')]
[script]
status agent:
    #!/usr/bin/env bash
    set -euo pipefail
    invocation_dir="{{ invocation_directory() }}"

    if [[ "{{ agent }}" != "omp" ]]; then
        echo "error: status currently supports only 'omp'" >&2
        exit 1
    fi

    found=0
    while read -r pid state etime command; do
        found=1
        version=$(sed -nE 's#.*oh-my-pi/([^/]+)/omp.*#\1#p' <<< "$command")
        args=$(sed -E 's#^.*oh-my-pi/[^ ]+/omp ?##' <<< "$command")
        cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
        marker=
        [[ "$cwd" == "$invocation_dir" ]] && marker=", current"
        if [[ -n "$args" ]]; then
            printf '%s — OMP %s, %s, %s%s\n' \
                "$pid" "$version" "$args" "$cwd" "$marker"
        else
            printf '%s — OMP %s, %s%s\n' \
                "$pid" "$version" "$cwd" "$marker"
        fi
    done < <(
        ps -axo pid=,state=,etime=,command= |
            awk '$0 ~ /oh-my-pi\/[^ ]+\/omp( |$)/ && $0 !~ /__omp_worker_/'
    )

    if (( ! found )); then
        echo "No running OMP sessions."
    fi

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
[script]
outdated:
    mise outdated --bump $(just _mise-bump-scan-tools)

# Lists outdated uv tools
[group('info')]
outdated-uv:
    mise exec -- uv tool list --outdated

# Lists Claude model IDs recorded in .claude/models.lock
[group('info')]
list-claude-models:
    @awk '/^  claude-/{print $1}' {{ justfile_directory() }}/.claude/models.lock

# Lists deprecated/retired Claude models and drift from .claude/models.lock
[group('info')]
outdated-models:
    scripts/claude-models.sh check

# Lists omp plugins whose installed version is behind the npm registry
[group('info')]
omp-plugins-outdated:
    #!/usr/bin/env bash
    set -euo pipefail
    found=0
    while IFS=$'\t' read -r pkg installed; do
        latest=$(npm view "$pkg" version 2>/dev/null) || continue
        if [ "$installed" != "$latest" ]; then
            echo "$pkg $installed → $latest"
            found=1
        fi
    done < <(omp plugin list --json | jq -r '.npm[] | [.name, .version] | @tsv')
    if [ "$found" -eq 0 ]; then
        echo "All omp plugins are up to date"
    fi

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
    mise bootstrap packages apply

# Installs Homebrew packages from Brewfile
[group('configuration')]
install-brew:
    brew bundle install

# Installs GitHub CLI extensions from manifest file
[group('configuration')]
[script]
install-gh-extensions:
    set -euo pipefail
    manifest="{{ gh_extensions_manifest }}"
    # A missing manifest is a no-op, not a failure
    if [[ ! -f "$manifest" ]]; then
        exit 0
    fi
    # Installed repos: `gh extension list` is tab-separated with no header row
    installed=$(gh extension list 2>/dev/null | awk -F'\t' '{print $2}' || echo "")
    # Read manifest and install missing extensions
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        repo="$line"
        # Check if already installed
        if grep -qxF "$repo" <<<"$installed"; then
            echo "✓ $repo already installed"
        else
            echo "Installing $repo..."
            gh extension install "$repo"
        fi
    done < "$manifest"

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

# Prints config-managed mise tools minus mise_bump_exclusions (space-separated, for --bump scans)
[script]
_mise-bump-scan-tools:
    mise config get tools | sed -nE 's/^\["?([^]"]+)"?\]$/\1/p; s/^"([^"]+)" = .*/\1/p; s/^([A-Za-z0-9_-]+) = .*/\1/p' | grep -vxFf <(echo "{{ mise_bump_exclusions }}" | tr ' ' '\n') | tr '\n' ' '

# Installs tools using mise
[group('configuration')]
deps: _check-github-token install-brew install-gh-extensions git-filters
    mise install

# Update tools within current versions
[group('configuration')]
update: update-rust

# Refreshes .claude/models.lock from the Claude API, committing any change
[group('configuration')]
[script]
update-models:
    set -euo pipefail
    scripts/claude-models.sh lock
    if [ -z "$(git status --porcelain -- .claude/models.lock)" ]; then
        echo "Model catalog unchanged"
        exit 0
    fi
    # Summarize what moved so the commit body documents the generation change.
    body=$(git diff -- .claude/models.lock | grep -E '^[+-]  claude-' | sed 's/^/  /' || true)
    git add .claude/models.lock
    git commit -m "chore(claude): Refresh model catalog lockfile" \
        -m "${body:-Initial model catalog lockfile.}"

# Sync Casper model metadata and pricing from live APIs
[group('configuration')]
[script]
update-casper-models:
    set -euo pipefail
    {{ justfile_directory() }}/scripts/sync-casper-models.sh
    if [ -z "$(git status --porcelain -- .omp/profiles/casper/agent/models.yml)" ]; then
        echo "Casper model catalog unchanged"
        exit 0
    fi
    git add .omp/profiles/casper/agent/models.yml
    git commit -m "chore(casper): sync models.yml with live catalog and pricing"

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
[script]
upgrade-mise-tools *args:
    if [ -z "{{ args }}" ]; then
        set -- $(just _mise-bump-scan-tools)
    else
        set -- {{ args }}
    fi
    mise upgrade --bump --yes "$@"

# Upgrades mise itself
[group('configuration')]
upgrade-mise:
    mise self-update --yes

# Upgrades the installed omp version from the upstream GitHub repository
[group('configuration')]
upgrade-omp:
    mise upgrade --bump github:can1357/oh-my-pi
    bash -ic 'cmt .config/mise/config.toml'

# Upgrades each outdated tool and commits the version change individually
[group('configuration')]
upgrade-mise-tools-commit:
    #!/usr/bin/env bash
    set -euo pipefail
    json=$(mise outdated --bump --json $(just _mise-bump-scan-tools) | jq 'with_entries(select(.value.bump | type == "string"))')
    if echo "$json" | jq -e 'type == "object" and (keys | length) == 0' >/dev/null 2>&1; then
        echo "All tools are up to date"
        exit 0
    fi
    echo "$json" | jq -r 'keys[]' | while read -r tool; do
        current=$(echo "$json" | jq -r --arg t "$tool" '.[$t].current')
        bump=$(echo "$json" | jq -r --arg t "$tool" '.[$t].bump')
        echo "Upgrading $tool: $current → $bump"
        mise upgrade --bump --yes "$tool"
        # --only commits this path from the working tree and disregards
        # anything else staged, so concurrent work is never swept into a
        # version-bump commit.
        git commit --only {{ justfile_directory() }}/.config/mise/config.toml \
            -m "chore: bump $tool $current → $bump"
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
    nix flake update --flake {{ justfile_directory() }}/.config/home-manager
    home-manager switch --flake {{ justfile_directory() }}/.config/home-manager

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
clean: clean-rust
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

# Opens the omp plugin manifest in the configured editor
[group('configuration')]
omp-plugins-edit:
    ${VISUAL:-${EDITOR:-vi}} {{ justfile_directory() }}/.omp/plugins/package.json

# Reinstalls omp plugins from the manifest, discarding node_modules
[group('configuration')]
omp-plugins-reinstall:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ justfile_directory() }}/.omp/plugins
    rm -rf node_modules
    bun install
    omp plugin doctor --fix

# Updates omp plugins in bun.lock to their latest allowed version and syncs the plugin manifest
[group('configuration')]
omp-plugins-update:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ justfile_directory() }}/.omp/plugins
    bun update
    omp plugin doctor --fix

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
    {{ justfile_directory() }}/scripts/sort-gitignore < {{ justfile_directory() }}/.gitignore | diff --brief - {{ justfile_directory() }}/.gitignore

# Lints Python scripts with ruff
[group('checks')]
lint-python:
    @echo "Linting Python scripts..."
    ruff check {{ justfile_directory() }}/scripts/agent-harnesses.py {{ justfile_directory() }}/scripts/harness_skills.py {{ justfile_directory() }}/scripts/sort-tools.py {{ justfile_directory() }}/scripts/format-json.py {{ justfile_directory() }}/scripts/audit-package-managers.py {{ justfile_directory() }}/scripts/audit-ignored-config.py {{ justfile_directory() }}/scripts/sort-codex-config.py {{ justfile_directory() }}/scripts/review-pr.py {{ justfile_directory() }}/scripts/sync-codex-casper-models.py {{ justfile_directory() }}/.agents/harness/hooks/safety.py
    ruff format --check {{ justfile_directory() }}/scripts/harness_skills.py {{ justfile_directory() }}/.agents/harness/hooks/safety.py

# Type-checks Python scripts with ty (scope mirrors pyproject's basedpyright include)
[group('checks')]
typecheck-python:
    @echo "Type-checking Python scripts..."
    ty check {{ justfile_directory() }}/scripts {{ justfile_directory() }}/.agents/harness/hooks/safety.py

# Checks Codex config formatting (alphabetized except native marketplace state order)
[group('checks')]
lint-toml:
    python3 {{ justfile_directory() }}/scripts/sort-codex-config.py --check {{ justfile_directory() }}/.codex/config.toml

# Checks mise config formatting and [tools] sort order (mirrors format-mise)
[group('checks')]
lint-mise:
    mise fmt --check
    python3 {{ justfile_directory() }}/scripts/sort-tools.py --check

# Checks all tracked JSON/JSONC config files are formatted (mirrors format-json)
[group('checks')]
lint-json:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    # Exclusions below must stay in sync with format-json
    git ls-files --cached '*.json' | while read -r f; do
        [[ "$f" == .claude/skills/gstack/* ]] && continue
        [[ "$f" == *.jsonc.json ]] && continue
        case "$f" in
            .claude/policy-limits.json) continue ;;
            .config/zed/settings.json) continue ;;
            .config/cmux/cmux.json) continue ;;
            "Library/Application Support/Claude/claude_desktop_config.json") continue ;;
        esac
        printf '%s\0' "$f"
    done | python3 {{ justfile_directory() }}/scripts/format-json.py --check
    jsonc_files=()
    while read -r f; do
        [[ "$f" == .claude/skills/gstack/* ]] && continue
        [[ "$f" == .config/opencode/opencode.jsonc ]] && continue
        jsonc_files+=("$f")
    done < <(git ls-files --cached '*.jsonc' '.config/zed/settings.json' '.config/cmux/cmux.json')
    if ((${#jsonc_files[@]})); then
        prettier --parser jsonc --check "${jsonc_files[@]}"
    fi

# Lints all tracked YAML config files with yamllint and prettier
[group('checks')]
[script]
lint-yaml:
    set -euo pipefail
    echo "Linting YAML config files..."
    files=()
    while read -r f; do
        # vendored third-party gstack workflows — never lint
        # Exclusions below must stay in sync with format-yaml
        [[ "$f" == .claude/skills/gstack/* ]] && continue
        files+=("$f")
    done < <(git ls-files --cached '*.yml' '*.yaml')
    if ((${#files[@]})); then
        mise exec -- yamllint "${files[@]}"
        # format-yaml writes with prettier but nothing verified it, so a file
        # could be prettier-dirty and still pass lint until `just format` later
        # produced a churn commit. This closes that gap the way lint-json
        # already gates JSON. It does NOT cover OMP's config.yml churn --
        # prettier reported all 12 historical versions clean; yamllint's
        # trailing-spaces rule is what catches those, and the yaml-normalize
        # clean filter keeps them out of the committed blob.
        prettier --check "${files[@]}"
    fi

# Lints Zsh functions with shellcheck

# Uses ksh dialect and excludes SC2168 (local in function body) since these are zsh autoload files
[group('checks')]
lint-zsh:
    @echo "Linting Zsh functions..."
    @find {{ justfile_directory() }}/.config/zsh/functions -type f -name '*' ! -name '.*' -exec shellcheck -s ksh -e SC2168 {} +

# Validates Nushell scripts syntax
[group('checks')]
lint-nushell:
    @echo "Validating Nushell scripts..."
    @nu --commands 'source {{ justfile_directory() }}/.config/nushell/config.nu'
    # config.nu does not source autoload/, and nu -c never loads it, so the
    # 267 autoload files had no syntax check at all. nu-check covers them all
    # in one process (~0.3s); a broken autoload file otherwise exits 0.
    @nu --commands 'let bad = (ls {{ justfile_directory() }}/.config/nushell/autoload/*.nu | get name | where {|f| not (nu-check $f) }); if ($bad | is-not-empty) { $bad | each {|f| print $"  ($f)" }; print "nushell parse errors"; exit 1 }'

# Lints GitHub Actions shell scripts with shellcheck
[group('checks')]
lint-github-scripts:
    @echo "Linting GitHub Actions scripts..."
    @find {{ justfile_directory() }}/.github/scripts -name '*.sh' -exec shellcheck {} +

# Lints bin scripts with shellcheck (excludes vendor scripts)
[group('checks')]
lint-bin:
    @echo "Linting bin scripts..."
    @find {{ justfile_directory() }}/bin -name '*.sh' ! -name 'dotnet-install.sh' -exec shellcheck {} +

# Checks shell scripts are shfmt-formatted and shellharden-clean (mirrors format-shell)
[group('checks')]
lint-shell:
    @echo "Checking shell script formatting..."
    @find {{ justfile_directory() }}/.config/zsh/functions -type f -name '*' ! -name '.*' $(printf '! -name %s ' {{ shfmt_exclude_functions }}) -exec shfmt -ln zsh -i 4 -sr -d {} +
    @find {{ justfile_directory() }}/.config/zsh/functions -type f -name '*' ! -name '.*' $(printf '! -name %s ' {{ shellharden_exclude_functions }}) -exec shellharden --check {} +
    @find {{ justfile_directory() }}/.github/scripts -name '*.sh' -exec shfmt -ln bash -i 4 -sr -d {} +
    @find {{ justfile_directory() }}/.github/scripts -name '*.sh' -exec shellharden --check {} +

# Checks tracked symlinks have relative targets when they resolve to tracked
# repo content (absolute targets resolve into the real $HOME from inside a
# worktree, returning whichever branch is checked out there instead of this
# tree's own content)
[group('checks')]
lint-symlinks:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    offenders=()
    while IFS=$'\t' read -r meta path; do
        [[ "${meta%% *}" == "120000" ]] || continue
        target=$(readlink "$path")
        [[ "$target" == "$HOME"/* ]] || continue
        rel="${target#"$HOME"/}"
        if git ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
            offenders+=("$path -> $target")
            continue
        fi
        # Target may itself pass through a tracked symlink (e.g. a directory
        # alias), so also check what it ultimately resolves to. A dangling
        # target (e.g. untracked app state that hasn't been generated yet)
        # is not tracked either way.
        real=$(realpath "$target" 2>/dev/null || true)
        if [[ -n "$real" && "$real" == "$HOME"/* ]]; then
            real_rel="${real#"$HOME"/}"
            if git ls-files --error-unmatch "$real_rel" >/dev/null 2>&1; then
                offenders+=("$path -> $target")
            fi
        fi
    done < <(git ls-files -s)
    if ((${#offenders[@]})); then
        echo "Tracked symlinks with absolute targets pointing at tracked repo content:" >&2
        printf '  %s\n' "${offenders[@]}" >&2
        echo "Convert to a relative target so worktrees resolve this repo's own content." >&2
        exit 1
    fi

# Checks spelling with typos
[group('checks')]
check-spelling:
    mise exec -- typos

# Runs all linting checks
[group('checks')]
lint-all: lint-zsh lint-nushell lint-github-scripts lint-bin
    @echo "All linting complete"

# Checks formatting/sort order for gitignore, python, toml, json, yaml, mise,
# and shell; tracked symlink targets; plus every lint-all linter
[group('checks')]
lint: lint-gitignore lint-python lint-toml lint-json lint-yaml lint-mise lint-shell lint-symlinks lint-all
    just --fmt --check

# Runs lint, harness parity checks, and test
[group('checks')]
check: lint check-spelling harness-check test

# Generates shared/native agent harness parity artifacts
[group('checks')]
harness-generate:
    python3 {{ justfile_directory() }}/scripts/agent-harnesses.py generate

# Validates shared/native agent harness parity artifacts
[group('checks')]
harness-check:
    python3 {{ justfile_directory() }}/scripts/agent-harnesses.py validate

# Reports gitignored harness config worth tracking (allowlist blind spots)
[group('checks')]
audit-ignored-config *ROOTS:
    python3 {{ justfile_directory() }}/scripts/audit-ignored-config.py {{ ROOTS }}

# Reports measured harness feature usage and friction from local session transcripts
[group('checks')]
harness-sessions *ARGS:
    python3 {{ justfile_directory() }}/scripts/harness-sessions.py {{ ARGS }}

# Audits installed harness versions and parity gaps
[group('checks')]
harness-audit:
    python3 {{ justfile_directory() }}/scripts/agent-harnesses.py audit

# Flags CLI tools installed via both mise and Homebrew
[group('checks')]
package-audit:
    python3 {{ justfile_directory() }}/scripts/audit-package-managers.py

# Runs bats tests in parallel; `just test abort` stops at the first failure
[group('tests')]
[script]
test mode="parallel":
    echo "Running tests..."
    eval "$(mise activate bash)"
    [[ -d /nix/var/nix/profiles/default/bin ]] && export PATH="$PATH:/nix/var/nix/profiles/default/bin:${HOME}/.nix-profile/bin" || true
    case "{{ mode }}" in
    parallel)
        # Tests within a file share fixtures (generated docs, SIGINT timing),
        # so parallelize across files only -- within-file parallelism races.
        # Fall back to a literal count: an empty --jobs makes bats run 0 tests.
        jobs=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
        bats --print-output-on-failure --jobs "$jobs" --no-parallelize-within-files --parallel-binary-name rush {{ justfile_directory() }}/tests/
        ;;
    abort)
        # --abort makes bats pass --halt to the parallel runner, which rush
        # does not support, so fail-fast has to run serially.
        bats --print-output-on-failure --abort {{ justfile_directory() }}/tests/
        ;;
    *)
        echo "Unknown mode '{{ mode }}' (expected: parallel, abort)" >&2
        exit 2
        ;;
    esac

# Sorts .gitignore with negation-aware ordering
[group('configuration')]
format-gitignore:
    {{ justfile_directory() }}/scripts/sort-gitignore < {{ justfile_directory() }}/.gitignore | sponge {{ justfile_directory() }}/.gitignore

# Formats the Codex config.toml (native marketplace state order, state clustered)
[group('configuration')]
format-toml:
    python3 {{ justfile_directory() }}/scripts/sort-codex-config.py {{ justfile_directory() }}/.codex/config.toml

# Formats and sorts mise config
[group('configuration')]
format-mise:
    #!/usr/bin/env bash
    set -euo pipefail
    mise fmt
    # Sort [tools] entries alphabetically while preserving the rest of the file
    python3 {{ justfile_directory() }}/scripts/sort-tools.py

# Formats all tracked JSON/JSONC config files with sorted keys
[group('configuration')]
format-json:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
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
    done | python3 {{ justfile_directory() }}/scripts/format-json.py
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

# Formats all tracked YAML config files with prettier
[group('configuration')]
format-yaml:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    files=()
    while read -r f; do
        # vendored third-party gstack workflows — never reformat
        [[ "$f" == .claude/skills/gstack/* ]] && continue
        files+=("$f")
    done < <(git ls-files --cached '*.yml' '*.yaml')
    if ((${#files[@]})); then
        prettier --write "${files[@]}"
    fi

# Formats Python policy modules with ruff
[group('configuration')]
format-python:
    @ruff format {{ justfile_directory() }}/scripts/harness_skills.py {{ justfile_directory() }}/.agents/harness/hooks/safety.py

# Formats and hardens shell scripts
[group('configuration')]
format-shell:
    @echo "Formatting shell scripts..."
    @find {{ justfile_directory() }}/.config/zsh/functions -type f -name '*' ! -name '.*' $(printf '! -name %s ' {{ shfmt_exclude_functions }}) -exec shfmt -ln zsh -w -i 4 -sr {} +
    @find {{ justfile_directory() }}/.config/zsh/functions -type f -name '*' ! -name '.*' $(printf '! -name %s ' {{ shellharden_exclude_functions }}) -exec shellharden --replace {} +
    @find {{ justfile_directory() }}/.github/scripts -name '*.sh' -exec shfmt -ln bash -w -i 4 -sr {} +
    @find {{ justfile_directory() }}/.github/scripts -name '*.sh' -exec shellharden --replace {} +

# Formats mise config, justfile, Python, JSON/TOML configs, and shell scripts
[group('configuration')]
format: format-gitignore format-mise format-toml format-json format-yaml format-python format-shell
    just --fmt

#
# git group recipes
#

# Installs git hooks from tracked directory
[group('git')]
git-hooks:
    git config --local core.hooksPath .config/git/hooks
    @echo "Git hooks installed from .config/git/hooks/"

# Installs git clean filters that strip churn/secrets before staging (see .gitattributes)
[group('git')]
git-filters:
    git config --local filter.codex-config.clean {{ justfile_directory() }}/scripts/mask-codex-state.sh
    git config --local filter.codex-config.smudge cat
    git config --local filter.codex-config.required true
    git config --local filter.oc-config.clean {{ justfile_directory() }}/scripts/mask-oc-config.sh
    git config --local filter.oc-config.smudge cat
    git config --local filter.oc-config.required true
    git config --local filter.pi-models-store.clean {{ justfile_directory() }}/scripts/mask-pi-models-store.sh
    git config --local filter.pi-models-store.smudge cat
    git config --local filter.pi-models-store.required true
    git config --local filter.yaml-normalize.clean {{ justfile_directory() }}/scripts/normalize-yaml-ws.sh
    git config --local filter.yaml-normalize.smudge cat
    git config --local filter.yaml-normalize.required true
    git config --local filter.antigravity-settings.clean {{ justfile_directory() }}/scripts/mask-antigravity.sh
    git config --local filter.antigravity-settings.smudge cat
    git config --local filter.antigravity-settings.required true
    @echo "Git filter 'codex-config' installed (masks ~/.codex/config.toml churn)"
    @echo "Git filter 'oc-config' installed (strips ~/.oc/config.json api_key)"
    @echo "Git filter 'pi-models-store' installed (masks ~/.pi/agent/models-store.json churn)"
    @echo "Git filter 'yaml-normalize' installed (strips trailing whitespace from ~/.omp/agent/config.yml)"
    @echo "Git filter 'antigravity-settings' installed (strips trustedWorkspaces from ~/.gemini/antigravity-cli/settings.json)"

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
