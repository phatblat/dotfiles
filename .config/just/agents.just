# agents — AI agent harness generation, parity, and drift tracking

# Installs cmux agent hooks; regenerates the machine-managed session bridges
# (~/.omp/agent/extensions/cmux-omp-session.ts et al.) that git now ignores
[group('agents')]
install-cmux-hooks:
    cmux hooks setup --yes

# Generates shared/native agent harness parity artifacts
[group('agents')]
harness-generate:
    python3 {{ justfile_directory() }}/scripts/agent-harnesses.py generate

# Applies the shared MCP set to Claude Code user scope (outside the dotfiles repo)
[group('agents')]
harness-mcp-apply:
    python3 {{ justfile_directory() }}/scripts/harness-apply.py mcp

# Applies the shared permission baseline to OMP's config.yml via `omp config set`
[group('agents')]
harness-perms-apply:
    python3 {{ justfile_directory() }}/scripts/harness-apply.py perms

# Validates shared/native agent harness parity artifacts
[group('agents')]
harness-check:
    python3 {{ justfile_directory() }}/scripts/agent-harnesses.py validate

# Reports gitignored harness config worth tracking (allowlist blind spots)
[group('agents')]
audit-ignored-config *ROOTS:
    python3 {{ justfile_directory() }}/scripts/audit-ignored-config.py {{ ROOTS }}

# Reports measured harness feature usage and friction from local session transcripts
[group('agents')]
harness-sessions *ARGS:
    python3 {{ justfile_directory() }}/scripts/harness-sessions.py {{ ARGS }}

# Audits installed harness versions and parity gaps
[group('agents')]
harness-audit:
    python3 {{ justfile_directory() }}/scripts/agent-harnesses.py audit

# Re-verifies harness capability probes, records CLI versions, appends drift
[group('agents')]
harness-probe *ARGS:
    python3 {{ justfile_directory() }}/scripts/agent-harnesses.py probe {{ ARGS }}

# Shows recent harness capability drift, newest first
[group('agents')]
harness-drift *ARGS:
    python3 {{ justfile_directory() }}/scripts/agent-harnesses.py drift {{ ARGS }}

# Checks agentlink's project-tier links still match .agentlink/config.toml.
# Part of `just check`, but not CI: `.agentlink/lock.toml`, `.github/skills`,
# and `.opencode/skills` are committed, but `.cursor/skills` is gitignored
# (via `.cursor/.gitignore`, not this file's own `[gitignore]` block, which
# stays `manage = false`) and so is never materialised in a fresh CI
# checkout, which would fail this check for a reason no CI run can fix.
[group('agents')]
agentlink-check:
    agentlink status --check --dir {{ justfile_directory() }}
