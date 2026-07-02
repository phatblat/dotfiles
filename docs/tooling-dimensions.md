# Tooling Dimensions

This repo maintains three separate axes of "mostly-similar tools that need to be kept
from silently drifting apart." Each axis has a different management strategy and a
different depth of automated gap-checking. This doc is the map; see the linked docs for
the details.

## The three dimensions

| Dimension | Members | Strategy | Automated gap-check |
|---|---|---|---|
| Package managers | mise, Homebrew, Nix/home-manager | mise primary, Homebrew fallback, Nix is an untracked experiment | `just package-audit` (basic, name-based, mise vs. installed brew) |
| Shells | Zsh, Fish, Nushell, Bash | Mirror functions across shells, using each shell's native idioms | `docs/functions.md` (manual coverage table) + `just lint-zsh`/`lint-fish`/`lint-nushell`/`lint-bin` (parse-only, not coverage) |
| Agent harnesses | Claude Code, Codex, OpenCode, Pi, Antigravity, Cursor | Shared source of truth under `.agents/harness/`, generated/adapted per harness | `just harness-check` (validates generated parity artifacts) + `just harness-audit` (installed versions, parity gaps) |

Harness parity is the deepest of the three: it has a generator, a schema-validated parity
table (`docs/agent-harnesses.md`), and a documented attribute-mapping table for porting
config between harnesses. See `scripts/agent-harnesses.py` and `docs/agent-harnesses.md`.

Shell parity is checked for correctness (each function file parses/lints in its shell)
but not for completeness — nothing currently fails a build if a function exists in Zsh
and Fish but is missing from Nushell. `docs/functions.md`'s coverage table is maintained
by hand today.

Package manager overlap is checked for correctness of a narrow slice (name-based
mise-vs-brew duplication) but doesn't catch alias mismatches (a mise package whose
binary name differs from the package name) or three-way overlaps involving Nix, since
Nix isn't expected to stay in sync in the first place.

## Where to go for more

- Package managers: `docs/package-management.md`
- Shells: `docs/functions.md`, and the "Shell Architecture" section of `~/CLAUDE.md`
- Agent harnesses: `docs/agent-harnesses.md`, `.agents/harness/instructions.md`

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
