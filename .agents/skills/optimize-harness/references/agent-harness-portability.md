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
7. When new research changes current agent configuration facts, update `ATTRIBUTE_MAPPINGS` in `scripts/harness_paths.py`, regenerate `docs/agent-harnesses.json` and `docs/agent-harnesses.md` via `just harness-generate`, and keep this reference aligned.

## Metadata Portability

The full attribute mapping table (all 8 harnesses) is generated from `ATTRIBUTE_MAPPINGS` in `scripts/harness_paths.py` — see the "Configuration Attribute Mapping" section of `docs/agent-harnesses.md` for the current table. Do not hand-maintain a second copy here; it drifts.

## Source Notes

- Open Agent Skills defines the portable skill shape and marks `allowed-tools` as experimental, so do not treat it as a shared contract without checking the target harness.
- Codex officially documents `agents/openai.yaml` for `interface`, `policy.allow_implicit_invocation`, and `dependencies.tools`. `allow_implicit_invocation: false` prevents implicit invocation; it does not remove enabled skill metadata from Codex's initial skill list.
- OpenCode documents skill `metadata` as a generic object and says it ignores unrecognized properties. That means a copied vendor key can be harmless but still ineffective.
- Cursor and Claude use overlapping field names for some skills, but overlap is not portability. Keep their metadata in generated adapters unless the Agent Skills spec or the target docs confirm the field.
- Pi, OMP, and Antigravity rows are based on local generated adapters in this repo, not verified primary docs.
