# Claude–OMP harness remediation

## Issue

The 30-day session scan parsed 741 Casper files and found 674 explicit invocations across 17 workflows; all 29 shared commands already have Claude entry points. Full configuration audit then found: Claude security guards fail open on hook failures/timeouts because no `onFailure: "block"` is set; the pre-commit formatter can act on the wrong repositories on `git -C`; the dotfiles copy of `claude` settings duplicates loaded configuration while shared instructions are not imported at all; skill policy is driven by parallel hand-maintained inclusion/manual lists which drift; specialist agents for Claude sit in `.claude/agents-disabled/`; OMP profiles lack shared agent/command/MCP links; Todoist MCP is not registered in Claude; Casper has no Anthropic login; ignored-config coverage misses genuine machine-state candidates; the Justfile PATH ordering can resolve a stale OMP; and archived debug prompts exist untracked.

Full plan and verification contract: `local://claude-omp-harness-remediation-plan.md`.

## Status

This is a proposal that is **accepted**.

## Assumptions and Constraints

- ness policy/state, `crates/ness/`, shared harness generators, and `.agents/harness/hooks/` are human-application control-plane surfaces; the agent prepares patches under `~/.local/state/ness/proposals/claude-omp-harness-remediation/`.
- Claude version floor for `onFailure` reliably honored is **2.1.295**; current Claude version 2.1.251 below it must be upgraded before new fields activate.
- OMP 18.18.6 active, `~/.local/bin/omp` is a Tern-managed path requiring Just's PATH endpoint reorder.
- Chosen launcher strategy: `cc`, `ccc`, `ccr` as scoped launchers; direct `claude`/`jan-claude` remain the full-settings paths.
- `.agents/skills` stays the workflow source, normalized `.agents/harness/agents/*.toml` the specialist source.
- Preserve existing `review-pr` variants while combining into one canonical shared variant.

## Argument

Make Claude fail closed and fully configured rather than rely on unused-source presence. **Chosen.**

Keep treating source presence as enough. **Rejected:** runtime sessions produced no retained Claude evidence, because the harness was not actually configured.

## Positions

- **Make the configuration source-derived** over parallel inclusion lists. Chosen: inclusion lists drift from sources.
- **Rely on hand-managed lists and treat generation as truth.** Rejected: the audit found drift between lists and sources.
- **Combine `review-pr` carefully** from the two variants rather than choosing one body wholesale. Chosen: Casper adds only the missing branch-discovery behavior on top of the richer default variant.
- **Choose one variant and discard the other's behavior.** Rejected for the same audit result: it loses either a full thread-suppression path or current branch detection.
- **Use host-native capabilities** for CLI requests referring to native delegation, planning, task tools and observability rather than emulating OMP devices. Chosen: emulated wrappers repeatedly misroute and require behavioral maintenance on par with folder-specific tools.
- **Wholesale copy OMP device wrappers.** Rejected: they are not portable, and each wrapper duplicates behavior already covered.
- **Enable Anthropic in Casper** through profile-scoped OAuth, not API-key models.yml. Chosen: avoids credential sprawl, uses same entitlement as the browser flow.
- **Use an API key in models.yml for Anthropic**. Rejected: it risks overriding OAuth and leaks logins across profiles.
- **Treat generated/runtime state directories as config**. Rejected: turning model/session state into config invites credential tracking.
- **Delete all archive prompts as clutter**. Rejected: the three `debug/*.md` prompts are useful; keep them tracked rather than deleting content.

## Architectural Decision

1. Require Claude ≥2.1.295, with `onFailure: "block"` on both security adapters and `minimumVersion: "2.1.295"` for future updates.
2. Anchor formatting to the actual command/file repository and launch dotfiles fallback sessions with user-only settings.
3. Load shared instructions and replace skill inclusion lists with source-derived coverage/policy; keep deterministic out-of-repo discovery.
4. Consolidate `review-pr`; promote portable managed abilities; activate all shared specialists and link shared agents/commands/MCP into named profiles.
5. Use native host tools instead of OMP-device emulation; record intentional native package boundaries.
6. Complete credential-free Todoist registration and use Casper-scoped Anthropic OAuth without changing model defaults.
7. Preserve useful archived prompts, classify generated state correctly, make Just respect caller PATH order, and prove the installed configuration end to end.
