# Remove Cursor and Grok harness and tooling support

## Issue

This decision extends [2026-10-12-consolidate-harness-parity-on-omp-and-claude-code](./2026-10-12-consolidate-harness-parity-on-omp-and-claude-code.md) and [2026-10-12-extract-ness-to-its-own-repository](./2026-10-12-extract-ness-to-its-own-repository.md), and supersedes every Cursor and Grok clause in them.

Cursor and Grok still carry a large share of the harness surface:

- 68 of the 351 generated paths: 48 under `.agents/harness/adapters/cursor`, 19 under `.grok`, and `.cursor/hooks.json`.
- One registry column each. The capability registry goes from 405 cells (45 capabilities × 9 harnesses) to 315 (45 × 7).
- Two session scanners in `scripts/harness-sessions.py`.
- Two `ness hook` adapters (`run_cursor`, `run_grok`), 15 of the 61 hook-corpus payloads, and 4 of the 220 guard cases.
- A pinned `grok` CLI, the `cursor` and `grok-bot` Homebrew casks, two Zed ACP agent entries, and a `cursor` fallback in the `edit` function.

The consolidation record measured use over 30 days: Cursor had 7 sessions and Grok had none, ever. The consolidation record kept Grok as a fallback and removed only Cursor's user-tier skill copies. At skills-plus-shim depth the Grok fallback still costs a guard shim, corpus cases, registry cells, and a scanner for a harness that has never been started.

## Status

This is a proposal that is **accepted**.

## Assumptions and Constraints

- OMP is the primary harness and Claude Code the second. Neither changes.
- The secret-path protections stay: the `[protected_paths]` entries for `.cursor/ai-tracking/`, `.grok/auth.json`, and `.grok/mcp_credentials.json`, with their guard cases. A removed harness can still leave those files on disk, and an agent must not read or write them.
- The `[shell] guarded` entries `cursor-agent` and `grok` stay. Removing a name makes the binary `unrecognized = "allow"`, which loosens the guard.
- Control-plane files (`scripts/agent-harnesses.py`, `crates/ness/**`, `.config/ness/policy.toml`, the hook shims) are changed by a human-run checkpoint script, not by an agent.
- History is not rewritten: accepted decisions, plans, handoffs, flywheel findings, and the drift ledger keep their Cursor and Grok mentions.
- Installed apps, CLIs, and the runtime data in `~/.cursor` and `~/.grok` are left in place on this machine.

## Argument

Remove both harnesses and their tooling entirely. **Chosen.** Use is zero (Grok) or near zero (Cursor), and every remaining piece is upkeep: regenerated files, registry cells that must be kept valid, and a hook adapter plus corpus that must track the policy.

Keep them as fallback-tier harnesses as the consolidation record left them. **Rejected.** The guard shim, corpus cases, registry cells, and scanners still cost upkeep for no use.

Remove the harness integration and keep the desktop apps and the CLI pin. **Rejected** by the owner: with the harness gone nothing in this repository would use them.

## Architectural Decision

1. **Policy.** Remove the `[shell] read_only` grants `grok --version`, `grok mcp doctor`, and `grok mcp list`, so `grok` is only a guarded launcher. Delete guard cases 140 and 141 for cursor and grok. Rename case 143 to `143-deny-control-plane-harness-guard-config.json` and attribute it to `crush`, since its pattern is generic. Cases 068, 069, 070, and both 095 cases stay.
2. **ness.** Delete `run_grok`, `run_cursor`, and their dispatch from `ness hook`, which then accepts `claude`, `codex`, `crush`, and `antigravity`. Delete the 15 Cursor and Grok hook-corpus payloads and the shim tests that exercise them. The crate version is unchanged.
3. **Generator and registry.** Remove `cursor` and `grok` from `scripts/harness_paths.py`, every registry cell and role, the renderers in `scripts/agent-harnesses.py`, both session scanners, and the `mcp_lifecycle` observation that only Grok emitted. Delete `.agents/harness/adapters/cursor`, `.grok`, and `.cursor` from the tree and `generated-paths.json`.
4. **Agentlink, CI, and ignore files.** Drop the `cursor` and `grok` providers and the `grok` provider file from agentlink, the `cursor-plugin-install` recipe, the CI parity filter paths, the hk stage entries, and the ignore-file entries.
5. **Apps and CLIs.** Drop the `grok` mise pin, the `cursor` and `grok-bot` casks, the Zed `grok-build` and `cursor` agent servers, and `cursor` from the `edit` fallback list in Nushell and Zsh.
6. **Skills and docs.** Remove Cursor and Grok from the harness skills, the hand-written harness docs, `AGENTS.md`, and the backlog. The Antigravity backlog item drops its Cursor half.
7. **`$HOME`.** Prune only the links left dangling by clauses 3 and 4, plus the `cursor-plugin-install` copy and the `~/.cursor/skills` agentlink link. Nothing is uninstalled and no runtime data is deleted.

## Positions

- **Keep the secret protections.** Chosen: they guard files that may still exist on disk and cost one regex alternation each.
- **Drop the `guarded` names with the harness.** Rejected: it would turn `cursor-agent` and `grok` into `unrecognized = "allow"`.
- **Uninstall the apps and CLIs and delete `~/.cursor` and `~/.grok` on this machine.** Rejected by the owner: the repository change does not require it, and the data may be wanted.
- **Amend the proposed 2026-10-12 records instead of writing a new one.** Rejected: the change crosses the Decision threshold and the older records cover other work.
