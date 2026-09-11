# mise — tool version management: install, list, search, upgrade

# ANSI colors for formatting output

color_green := '\e[32m'
color_reset := '\e[0m'

# Tools excluded from `mise ... --bump` scans; each emits unfixable mise warnings and its
# bump is always null: wookie = rev-pinned cargo git ref (latest resolves to the ref string
# "HEAD"), dsh = prerelease-only npm package (mise resolves no "latest"), cursor-cli = http
# backend without version_list_url (cursor.com publishes no version feed).

mise_bump_exclusions := 'cargo:https://github.com/nkotval-ditto/wookie npm:@deepseek-ai/dsh http:cursor-cli'

alias ls := list
alias lsm := list-missing
alias od := outdated

# Lists installed tools managed by mise
[group('mise')]
list:
    mise list --global

# Lists missing tools managed by mise
[group('mise')]
list-missing:
    mise list --global --missing

# Lists available upgrades
[group('mise')]
[script]
outdated:
    mise outdated --bump $(just _mise-bump-scan-tools)

# Search for a tool in mise or homebrew
[group('mise')]
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

# Adds a new tool using mise, installing the latest version
[group('mise')]
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
[group('mise')]
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
[group('mise')]
install-mise:
    curl https://mise.run | sh
    mise bootstrap packages apply

# Verifies GitHub auth/rate-limit before mise installs, so a silent 403 wall surfaces as a clear error
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

# Upgrades tools using mise
[group('mise')]
[script]
upgrade-mise-tools *args:
    if [ -z "{{ args }}" ]; then
        set -- $(just _mise-bump-scan-tools)
    else
        set -- {{ args }}
    fi
    mise upgrade --bump --yes "$@"

# Upgrades mise itself
[group('mise')]
upgrade-mise:
    mise self-update --yes

# Upgrades each outdated tool and commits the version change individually
[group('mise')]
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
        hk fix .config/mise/config.toml
        paths=("{{ justfile_directory() }}/.config/mise/config.toml")
        if [ "$tool" = "hk" ]; then
            # hk.pkl pins the exact hk release it amends (see hk.pkl's own
            # comment: hk embeds that Pkl package for its own version and
            # evaluates hk.pkl with no network request; any other pin
            # downloads it on every run). Keep the pin in lockstep with the
            # version mise just installed, and fail loudly before committing
            # if the bump breaks the schema.
            sed -i '' -E "s|(amends \"package://github.com/jdx/hk/releases/download/v)[0-9.]+(/hk@)[0-9.]+(#/Config.pkl\")|\1${bump}\2${bump}\3|" hk.pkl
            sed -i '' -E "s|(min_hk_version = \")[0-9.]+(\")|\1${bump}\2|" hk.pkl
            mise x -- hk validate --quiet
            paths+=("{{ justfile_directory() }}/hk.pkl")
        fi
        # --only commits these paths from the working tree and disregards
        # anything else staged, so concurrent work is never swept into a
        # version-bump commit.
        git commit --only "${paths[@]}" \
            -m "chore: bump $tool $current → $bump"
    done
