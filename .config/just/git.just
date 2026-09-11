# git — hooks, clean filters, and GitHub CLI extensions

# GitHub CLI extensions manifest file (one OWNER/REPO per line, read by install-gh-extensions)

gh_extensions_manifest := '.config/gh/extensions.txt'

# Installs GitHub CLI extensions from manifest file
[group('git')]
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

# Installs git hooks with hk (steps live in hk.pkl)
[group('git')]
git-hooks:
    hk install --mise
    @echo "Git hooks installed by hk (hook.hk-pre-commit.command in .git/config)"

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
    git config --local filter.claude-json.clean {{ justfile_directory() }}/scripts/mask-claude-json.sh
    git config --local filter.claude-json.smudge cat
    git config --local filter.claude-json.required true
    @echo "Git filter 'codex-config' installed (masks ~/.codex/config.toml churn)"
    @echo "Git filter 'oc-config' installed (strips ~/.oc/config.json api_key)"
    @echo "Git filter 'pi-models-store' installed (masks ~/.pi/agent/models-store.json churn)"
    @echo "Git filter 'yaml-normalize' installed (strips trailing whitespace from ~/.omp/agent/config.yml)"
    @echo "Git filter 'antigravity-settings' installed (strips trustedWorkspaces from ~/.gemini/antigravity-cli/settings.json)"
    @echo "Git filter 'claude-json' installed (allowlists MCP fields from ~/.claude.json)"
