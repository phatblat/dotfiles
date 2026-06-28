# Agent Harness Portability

Use this reference when optimizing or porting shared skills, commands, agents, hooks, MCP config, and related metadata between Claude, Codex, OpenCode, Pi, Antigravity, and Cursor.

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
   - Pi and Antigravity: local generated adapter files until primary docs are verified.
4. Use progressive disclosure. Keep `SKILL.md` short; put detailed mapping tables in references, deterministic repeated work in scripts, and output assets in assets.
5. Declare tool dependencies where the target can use them. Codex supports `agents/openai.yaml` `dependencies.tools`; other harnesses need native MCP/config entries or adapter checks.
6. Record unsupported behavior as a parity gap instead of copying unknown metadata across tools.

## Metadata Portability

| Feature | Portable Guidance | Claude | Codex | OpenCode | Pi | Antigravity | Cursor |
|---|---|---|---|---|---|---|---|
| Skill identity and trigger | Portable core is `name` and `description`. | `SKILL.md` frontmatter | `SKILL.md` frontmatter | `SKILL.md` frontmatter | Local `skills` path adapter | Generated wrapper skill | `SKILL.md` frontmatter |
| Manual-only procedural skills | Map intent per harness; do not copy one vendor key everywhere. | `disable-model-invocation: true` | `agents/openai.yaml` `policy.allow_implicit_invocation: false` | No direct equivalent; use skill permissions or command wrappers | Adapter or command wrapper | Adapter or command wrapper | `disable-model-invocation: true` |
| File/path scope | Use only when documented by the target harness. | `paths` frontmatter | Prefer nested repo skills or concise descriptions | Directory discovery plus permissions | Adapter only | Adapter only | `paths`; legacy `globs` fallback |
| Skill-level tool preapproval | Treat `allowed-tools` as nonportable and client-specific. | `allowed-tools` and `disallowed-tools` | No skill-level allowlist; use permissions, hooks, or dependency metadata | `permission.skill` controls skill loading, not tool preapproval | Extension/settings adapter | Hook/adapter guard | No documented skill-level equivalent |
| Skill UI metadata | Keep presentation metadata in harness-specific sidecars. | Skill frontmatter or plugin metadata | `agents/openai.yaml` `interface` | `metadata` map only; unknown fields ignored | Local settings/extension only | Plugin manifest or adapter metadata | `metadata` map for skills; `.mdc` frontmatter for rules |
| Model and effort overrides | Map separately for skills, agents, and global config. | Skill/agent `model`, `effort` | Agent TOML `model`, `model_reasoning_effort` | Global or agent `model`; `small_model` | `defaultModel`, `defaultThinkingLevel` | Not verified in adapter | No shared skill metadata equivalent |
| Subagent tool restrictions | Prefer native agent config; use shared hooks for cross-harness safety. | Agent `tools`, `disallowedTools`, `permissionMode` | Agent TOML permissions/sandbox and inherited MCP config | Agent `permission` and `tools` | Extension-enforced guard | Generated hook/guard adapter | Rules/plugin adapter; native behavior unverified |
| MCP/tool dependencies | Declare dependencies near the harness that can enforce or install them. | `.mcp.json`, settings, or agent `mcpServers` | `agents/openai.yaml` `dependencies.tools` plus `config.toml` MCP | `mcp` config | Extension or future MCP bridge | Generated `mcp.json`, unverified | Generated `mcp.json`, unverified |

## Source Notes

- Open Agent Skills defines the portable skill shape and marks `allowed-tools` as experimental, so do not treat it as a shared contract without checking the target harness.
- Codex officially documents `agents/openai.yaml` for `interface`, `policy.allow_implicit_invocation`, and `dependencies.tools`. `allow_implicit_invocation: false` prevents implicit invocation; it does not remove enabled skill metadata from Codex's initial skill list.
- OpenCode documents skill `metadata` as a generic object and says it ignores unrecognized properties. That means a copied vendor key can be harmless but still ineffective.
- Cursor and Claude use overlapping field names for some skills, but overlap is not portability. Keep their metadata in generated adapters unless the Agent Skills spec or the target docs confirm the field.
- Pi and Antigravity rows are based on local generated adapters in this repo, not verified primary docs.
