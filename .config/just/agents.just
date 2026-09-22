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

# Applies agentlink's project-tier links per .agentlink/config.toml
[group('agents')]
agentlink-apply:
    agentlink apply --dir {{ justfile_directory() }}

# Runs Harbor evals for the shared agent harness
[group('agents')]
harness-evals:
    #!/usr/bin/env bash
    set -euo pipefail
    # Copy only these tracked harness files into the snapshot (evals/ is never included)
    SNAPSHOT_DIR="{{ justfile_directory() }}/.agents/harness/evals/harbor/harness-structure/environment/snapshot"
    rm -rf "$SNAPSHOT_DIR"
    mkdir -p "$SNAPSHOT_DIR"
    cd {{ justfile_directory() }}/.agents/harness
    cp -r README.md instructions.md adapters commands agents hooks \
          generated-paths.json self-improve-policy.json \
          "$SNAPSHOT_DIR/"
    # Run Harbor eval
    mise exec -- harbor run -p {{ justfile_directory() }}/.agents/harness/evals/harbor/harness-structure -a nop

# Rebuilds the graphify knowledge graph from scratch, rooted at this checkout.
# --code-only keeps it key-free (no LLM API key is set on this machine); docs
# and other non-code files enter the graph via `just graphify-semantic`.
[group('agents')]
[script]
graphify-reindex: && _graphify-pin
    rm -rf {{ justfile_directory() }}/graphify-out
    mise exec -- graphify extract {{ justfile_directory() }} --code-only --out {{ justfile_directory() }}

# Incremental re-index plus lessons refresh; driven daily by the
# at.phatbl.graphify-refresh LaunchAgent.
[group('agents')]
[script]
graphify-refresh: && _graphify-pin
    mise exec -- graphify update {{ justfile_directory() }}
    mise exec -- graphify reflect \
        --memory-dir {{ justfile_directory() }}/graphify-out/memory \
        --out {{ justfile_directory() }}/graphify-out/reflections/LESSONS.md \
        --graph {{ justfile_directory() }}/graphify-out/graph.json
    mise exec -- graphify check-update {{ justfile_directory() }}

# Adds the doc/paper/image layer the key-free rebuild skips. Uses the local
# Claude Code CLI as the backend, so it needs no API key, but it is a long LLM
# pass over the whole corpus - run it deliberately, never on a schedule.
[group('agents')]
graphify-semantic:
    mise exec -- graphify extract {{ justfile_directory() }} --backend claude-cli --out {{ justfile_directory() }}

# Re-pins the sidecars the graphify skill reads. The skill resolves its
# interpreter through `uv tool run --from graphifyy` first and caches the
# absolute path in .graphify_python; that path dies on the next graphifyy
# version bump (it was still pinned to the removed 0.9.16 install while mise
# had 0.9.65). Rewriting both sidecars keeps the skill on the mise-pinned
# install and on the correct scan root.
[script]
_graphify-pin:
    mkdir -p {{ justfile_directory() }}/graphify-out
    printf '%s\n' "$(head -1 "$(mise which graphify)" | sed 's|^#!||')" > {{ justfile_directory() }}/graphify-out/.graphify_python
    printf '%s\n' "{{ justfile_directory() }}" > {{ justfile_directory() }}/graphify-out/.graphify_root
