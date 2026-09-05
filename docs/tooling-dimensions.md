# Tooling Dimensions

This repo maintains three separate axes of "mostly-similar tools that need to be kept
from silently drifting apart." Each axis has a different management strategy and a
different depth of automated gap-checking. This doc is the map; see the linked docs for
the details.

## The three dimensions

| Dimension | Members | Strategy | Automated gap-check |
|---|---|---|---|
| Package managers | mise, Homebrew, Nix/home-manager | mise primary, Homebrew fallback, Nix is an untracked experiment | `just package-audit` (basic, name-based, mise vs. installed brew) |
| Shells | Zsh, Nushell, Bash | Mirror functions across shells, using each shell's native idioms | `docs/functions.md` (manual coverage table) + `just lint-zsh`/`lint-nushell`/`lint-bin` (parse-only, not coverage) |
| Agent harnesses | Claude Code, Codex, OpenCode, Pi, OMP, Antigravity, Cursor, Grok, Crush | Shared source of truth under `.agents/harness/`, generated/adapted per harness | `just harness-check` (validates generated parity artifacts) + `just harness-audit` (installed versions, parity gaps) + `just harness-probe` (re-verifies capability probes, records CLI versions, appends drift) |

Harness parity is the deepest of the three. A capability registry
(`scripts/harness_capabilities.py`) holds one cell per (harness, capability) with
its parity, mode, native surface, and cited evidence; `docs/agent-harnesses.md` is
the index (coverage, per-harness and per-domain counts, and every open item
attributed to the one harness that owes it); `docs/harness/<domain>.md` carries the
transposed per-capability tables; `docs/harness/porting.md` keeps the wide
all-harnesses grid used when porting config; `docs/harness/divergence.md` registers
permanent differences that will never close; and `docs/harness/drift.jsonl` plus
`docs/harness/versions.json` record what changed after a release. See
`scripts/agent-harnesses.py`, and run `just harness-drift` for the recent ledger.

Shell parity is checked for correctness (each function file parses/lints in its shell)
but not for completeness — nothing currently fails a build if a function exists in Zsh
but is missing from Nushell. `docs/functions.md`'s coverage table is maintained
by hand today.

Package manager overlap is checked for correctness of a narrow slice (name-based
mise-vs-brew duplication) but doesn't catch alias mismatches (a mise package whose
binary name differs from the package name) or three-way overlaps involving Nix, since
Nix isn't expected to stay in sync in the first place.

## agentlink (external, project tier)

`agentlink` (pinned in `.config/mise/config.toml` as
`"github:fialhosoft/agentlink" = "0.0.1"`) solves placement, not generation: for the
two resources whose format already converged — `AGENTS.md` and `SKILL.md` — it points
each agent's expected path at one canonical location instead of copying files. Its
canonical layout is `AGENTS.md` + `.agents/`, which is what this repo already uses, so
most of its verdicts are `native` (nothing written at all) and the rest are symlinks.

Because the workspace root here is `$HOME`, agentlink's project scope and this repo are
the same directory. Its links therefore serve agents working *in the dotfiles repo*,
while `scripts/agent-harnesses.py` keeps serving the user tier for all nine harnesses.
`~/.agents/skills` is canonical for both, and no file is written by both.

Config lives in `.agentlink/config.toml` plus `.agentlink/providers/` (four manifests
agentlink does not ship), both tracked. `.agentlink/lock.toml` and the three link
targets are per-developer and gitignored. `just agentlink-check` is part of
`just check`, but not CI, because a fresh checkout has no materialised links.

| Provider | Resource | Strategy | Path | Manifest |
|---|---|---|---|---|
| antigravity | instructions | native | `AGENTS.md` | embedded |
| antigravity | skills | native | `.agents/skills` | embedded |
| codex | instructions | native | `AGENTS.md` | embedded |
| codex | skills | native | `.agents/skills` | embedded |
| cursor | instructions | native | `AGENTS.md` | embedded |
| cursor | skills | link | `.cursor/skills` | embedded |
| github-copilot | instructions | native | `AGENTS.md` | embedded |
| github-copilot | skills | link | `.github/skills` | embedded |
| opencode | instructions | native | `AGENTS.md` | embedded |
| opencode | skills | link | `.opencode/skills` | embedded |
| omp | instructions | native | `AGENTS.md` | `.agentlink/providers/omp.toml` |
| omp | skills | native | `.agents/skills` | `.agentlink/providers/omp.toml` |
| pi | skills | native | `.agents/skills` | `.agentlink/providers/pi.toml` |
| grok | skills | native | `.agents/skills` | `.agentlink/providers/grok.toml` |
| crush | skills | native | `.agents/skills` | `.agentlink/providers/crush.toml` |

`claude-code` is the one embedded provider this repo does not serve. agentlink wants
`CLAUDE.md` → `AGENTS.md` and `.claude/skills` → `.agents/skills`, but `~/CLAUDE.md` is
separate hand-authored Claude guidance and `~/.claude/skills` holds third-party skills
(gstack) alongside the generated shared pointers. Both capabilities are permanently
`blocked`, so the provider is left out of `providers` and `agentlink status --check`
stays meaningful.

### Why this does not replace the generator

- Scope: agentlink 0.0.1 covers instructions and skills only. Commands, specialist
  agents, hooks, MCP, permissions and per-harness settings — most of what
  `scripts/agent-harnesses.py` emits — are outside its model, because those formats
  genuinely differ per vendor.
- Selection and metadata: the generator emits pointer files for a chosen subset (the 30
  names in `NATIVE_SKILL_ADAPTERS`, not all 69 shared skills) and stamps per-harness
  frontmatter on them (`disable-model-invocation: true` for the 10 manual-only skills,
  plus Codex `agents/openai.yaml` policy sidecars). One symlinked directory can express
  neither a subset nor per-harness metadata.
- Coexistence: the generator's targets are different paths from agentlink's
  (`~/.config/opencode/skills` vs `.opencode/skills`;
  `~/.agents/harness/adapters/cursor/skills` vs `.cursor/skills`), so both can be in
  place without fighting.
- `.gitignore`: agentlink maintains a marked block; `scripts/sort-gitignore` (enforced
  by `just lint-gitignore`) strips those markers and sorts the entries into the file.
  Ownership goes to the sorter — `[gitignore] manage = false` in
  `.agentlink/config.toml`, with the four entries tracked in sorted position.

## Extraction decision

The agent-harness system in this repo has been proposed for extraction into a
standalone product, rewritten as a compiled binary. That thesis is unvalidated
today, so extraction is deferred to a data-driven trigger rather than decided
on feel. The daily `at.phatbl.harness-probe` LaunchAgent (`just harness-probe`)
is what accumulates the evidence these conditions are measured against.

- **Extract** when coverage reaches ≥60% (243/405 cells) **and**
  `docs/harness/drift.jsonl` holds ≥10 distinct records **and** ≥3 of those
  records prompted a real config change. At that point the ledger has
  demonstrably tracked vendor movement and is worth packaging.
- **Abandon the product framing** if after 90 days of daily probes coverage is
  <30% or the ledger holds <3 records. That outcome means the vendors are not
  moving fast enough to justify a parity ledger, and what exists is a
  generator, not a knowledge base — in which case it stays in dotfiles
  permanently, and the compiled guard (`crates/ness/`) and decoupled source of
  truth (`.agents/harness/{commands,agents}/`) remain worthwhile on their own,
  independent of whether the ledger ever graduates.

## Where to go for more

- Package managers: `docs/package-management.md`
- Shells: `docs/functions.md`, and the "Shell Architecture" section of `~/CLAUDE.md`
- Agent harnesses: `docs/agent-harnesses.md`, `docs/harness/`, `.agents/harness/instructions.md`, `.agentlink/config.toml`

## Future automation ideas

Ideas for closing the remaining gaps, roughly in order of effort:

1. **Shell completeness gate** — extend the bats shell tests (or a small script) to parse
   `docs/functions.md`'s coverage table and fail if a function marked "implemented" in one
   shell has no corresponding file in another shell marked as also implementing it.
2. **Package manager alias map** — give `scripts/audit-package-managers.py` a small,
   manually-curated alias table (package name -> binary name) for known mismatches like
   `jujutsu`/`jj`, to reduce false negatives without the complexity of resolving binaries
   at runtime.
3. **CI-style gate for harness parity** — `just harness-check` already exists and runs in
   `just check`; consider whether `just package-audit` should eventually graduate into a
   blocking check once the mise/Homebrew tool set stabilizes, rather than staying
   informational.
4. **Single audit entrypoint** — a `just audit-all` (or similar) that runs
   `package-audit`, `harness-audit`, and a future shell-completeness check together, for a
   single "how much has drifted" report.
