# claude — Claude Code install, upgrade, models, and usage

alias uc := upgrade-claude
alias ub := usage-board

# Lists Claude model IDs recorded in .claude/models.lock
[group('claude')]
list-claude-models:
    @awk '/^  claude-/{print $1}' {{ justfile_directory() }}/.claude/models.lock

# Lists deprecated/retired Claude models and drift from .claude/models.lock
[group('claude')]
outdated-models:
    scripts/claude-models.sh check

# Refreshes .claude/models.lock from the Claude API, committing any change
[group('claude')]
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
