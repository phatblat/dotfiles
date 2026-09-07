# Agent Harness Portability

Use this reference when optimizing or porting shared skills, commands, agents, hooks, MCP config, and related metadata between the eight supported harnesses (`claude`, `codex`, `opencode`, `pi`, `omp`, `antigravity`, `cursor`, `grok`).

## Porting Rules

1. Classify every skill before mapping metadata.
   - Procedural: user-run workflows, migrated slash commands, interviews, commits, PR updates, or audits that should run only on explicit request.
   - Ability: reusable model-invoked capability or domain rule the agent should apply automatically when the task matches.
2. Treat `SKILL.md` as the portable core. Keep `name` and `description` accurate and front-loaded. Do not assume extra frontmatter keys are portable.
3. Put harness-specific behavior in the target's native sidecar or adapter:
   - Codex: `agents/openai.yaml` and `~/.codex/config.toml`.
   - Claude: slash command, agent, settings, or skill metadata.
   - OpenCode: `opencode.jsonc` config and plugin hooks.
   - Cursor: `.mdc` rules, generated plugin config, and skill wrappers.
   - Pi, OMP, and Antigravity: local generated adapter files until primary docs are verified.
4. Use progressive disclosure. Keep `SKILL.md` short; put detailed mapping tables in references, deterministic repeated work in scripts, and output assets in assets.
5. Declare tool dependencies where the target can use them. Codex supports `agents/openai.yaml` `dependencies.tools`; other harnesses need native MCP/config entries or adapter checks.
6. Record unsupported behavior as a parity gap instead of copying unknown metadata across tools.
7. When new research changes current agent configuration facts, update the matching `Cell.surface` and `Capability.porting` in `CAPABILITIES` in `scripts/harness_capabilities.py`, regenerate `docs/agent-harnesses.*` and `docs/harness/` via `just harness-generate`, and keep this reference aligned. The `harness-research` skill is the full procedure.

## Metadata Portability

The full porting grid (all 9 harnesses) is generated from `CAPABILITIES` in `scripts/harness_capabilities.py` — see `docs/harness/porting.md` for the current table, and the per-domain pages under `docs/harness/` for one capability's parity across harnesses. Do not hand-maintain a second copy here; it drifts.

## Source Notes

- Open Agent Skills defines the portable skill shape and marks `allowed-tools` as experimental, so do not treat it as a shared contract without checking the target harness.
- Codex officially documents `agents/openai.yaml` for `interface`, `policy.allow_implicit_invocation`, and `dependencies.tools`. `allow_implicit_invocation: false` prevents implicit invocation; it does not remove enabled skill metadata from Codex's initial skill list.
- OpenCode documents skill `metadata` as a generic object and says it ignores unrecognized properties. That means a copied vendor key can be harmless but still ineffective.
- Cursor and Claude use overlapping field names for some skills, but overlap is not portability. Keep their metadata in generated adapters unless the Agent Skills spec or the target docs confirm the field.
- Pi, OMP, and Antigravity rows are based on local generated adapters in this repo, not verified primary docs.

## Known Gaps

- **Antigravity has no implicit-invocation gate for procedural skills.** Codex's `agents/openai.yaml` `policy.allow_implicit_invocation: false` has no Antigravity equivalent: no `.yaml`/`.yml` policy file exists anywhere under `~/.agents/harness/adapters/antigravity/skills/`, and the antigravity skill-emission loop in `scripts/agent-harnesses.py` applies no `manual_only` filter (unlike the parallel Claude-targeted branch). All 73 wired skills — including purely procedural, user-run workflows like `git-commit` and `pr-create` — are equally auto-invokable on Antigravity today. `git commit` is one of only 8 `unsandboxed(...)` allow-listed patterns in `~/.gemini/antigravity-cli/settings.json`, so an auto-triggered procedural skill has no config-level backstop. Recorded here (2026-09-07 optimize-harness audit) per rule 6 above, instead of inventing a nonexistent invocation-mode field; confirm whether Antigravity's real skill schema exposes one before attempting a fix.
