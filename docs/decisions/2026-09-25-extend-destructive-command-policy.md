# Extend the destructive-command policy with the gstack guard patterns

## Issue

gstack shipped four guard skills — `careful`, `freeze`, `guard`, `unfreeze` —
that enforced through real `PreToolUse` hooks declared in SKILL.md frontmatter,
not prompt-level instruction. `careful/bin/check-careful.sh` read the tool input
JSON and returned `{"permissionDecision":"ask"}` on a match. That mechanism is
being deleted with the rest of gstack, and its `hooks:` frontmatter field is
Claude-Code-specific anyway, so it could never have carried to the other seven
harnesses.

The pattern list is worth keeping. Comparing `check-careful.sh` against
`crates/ness/src/policy.rs`'s `DANGEROUS_COMMANDS`, the shared policy already
covers `rm -rf` against root-ish targets, `mkfs`, `dd` to `/dev/`, `chmod 777`,
`chmod +s`, fork bombs, `curl | sh`, and `truncate`/`shred`. Six classes that
gstack warned on have no equivalent:

| Class | gstack pattern | ness today |
|---|---|---|
| Force-push | `git\s+push\s+.*(-f\b\|--force)` | uncovered |
| Hard reset | `git\s+reset\s+--hard` | uncovered |
| Discard worktree | `git\s+(checkout\|restore)\s+\.` | uncovered |
| Cluster delete | `kubectl\s+delete` | uncovered |
| Container destruction | `docker\s+(rm\s+-f\|system\s+prune)` | uncovered |
| SQL destruction | `drop\s+(table\|database)` | uncovered (`truncate` is covered) |

`rm -r <arbitrary-path>` is a seventh, partially covered case: ness denies only
when the target is `/`, `~`, `*`, or `..`, so `rm -rf src/` passes silently.
gstack allowed recursive delete against an explicit build-artifact allowlist
(`node_modules`, `dist`, `.next`, `__pycache__`, `.cache`, `build`, `.turbo`,
`coverage`) and warned on everything else.

## Status

This is a proposal that is **pending review**. `crates/ness/` is control plane —
`CONTROL_PLANE_FRAGMENTS` lists `/crates/ness/(?!target(?:/|$))`, so the guard
denies agent edits to it by design. This record exists so the change is reviewed
and applied by hand rather than smuggled in by the agent that proposed it.

## Assumptions and Constraints

- `tests/corpus/9xx-*.json` pins every control-plane fragment to a deny/allow
  case, and the file header requires a fragment and its corpus case to land in
  the same change. New patterns inherit that requirement.
- The six new classes are `ask`-grade in gstack, not `deny`-grade. The shared
  policy has no "ask" tier in `DANGEROUS_COMMANDS` — matches deny. Choosing the
  tier is the reviewer's call, and it is the one genuinely contentious part of
  this proposal.
- `git push --force-with-lease` is the safe form and must not be caught by a
  naive `--force` match.
- A recursive-delete allowlist is only sound if it matches the *resolved* target,
  not a substring: `rm -rf node_modules/../src` must not pass.

## Argument

Add the six classes to `DANGEROUS_COMMANDS` as deny patterns. **Recommended.**
They are unambiguous, each one destroys work that is expensive or impossible to
recover, and the guard already fails closed elsewhere. The cost is friction on
legitimate `git reset --hard` and `kubectl delete` during ordinary work.

Add them as a new `ASK`-tier list, mirroring gstack's semantics. **Rejected for
now**: it introduces a second decision tier across every harness adapter, and the
contract at `~/.agents/harness/hooks/contract.json` normalizes to
allow/deny/ask per host with uneven support. That is a larger change than the
pattern list justifies, and it should be its own decision.

Do nothing and let the patterns die with gstack. **Rejected**: the audit that
produced this record found the gap by accident — a routine `grep` of
`policy.rs` was denied while `git reset --hard` would not have been. The
asymmetry is the argument.

## Architectural Decision

Proposed, pending the tier question above.

1. **Six additions to `DANGEROUS_COMMANDS`** in `crates/ness/src/policy.rs`:

   ```rust
   // Force-push rewrites remote history; --force-with-lease is the safe form.
   Regex::new(r"(?i)\bgit\s+push\b[^;|&]*\s(?:-f|--force)(?![\w-])").unwrap(),
   Regex::new(r"(?i)\bgit\s+reset\s+--hard\b").unwrap(),
   Regex::new(r"(?i)\bgit\s+(?:checkout|restore)\s+\.(?:\s|$)").unwrap(),
   Regex::new(r"(?i)\bkubectl\s+delete\b").unwrap(),
   Regex::new(r"(?i)\bdocker\s+(?:rm\s+-f|system\s+prune)\b").unwrap(),
   Regex::new(r"(?i)\bdrop\s+(?:table|database)\b").unwrap(),
   ```

   The force-push pattern's `(?![\w-])` is what keeps `--force-with-lease`
   passing; verify that with a corpus case rather than by reading.

2. **Recursive delete outside the allowlist** is deliberately *not* proposed as a
   regex. It needs target resolution to be correct, which belongs in the
   `MUTATING_ARGV` span logic that already extracts `rm` arguments, not in a
   pattern. File it separately if wanted.

3. **Corpus cases**, one per pattern, following `904-allow-bash-rm-ness-target.json`:

   | File | `command` | `decision` |
   |---|---|---|
   | `910-deny-bash-git-force-push.json` | `git push -f origin main` | `deny` |
   | `911-allow-bash-git-force-with-lease.json` | `git push --force-with-lease origin main` | `allow` |
   | `912-deny-bash-git-reset-hard.json` | `git reset --hard HEAD~3` | `deny` |
   | `913-deny-bash-git-checkout-dot.json` | `git checkout .` | `deny` |
   | `914-deny-bash-kubectl-delete.json` | `kubectl delete pod web-0` | `deny` |
   | `915-deny-bash-docker-prune.json` | `docker system prune -a` | `deny` |
   | `916-deny-bash-sql-drop-table.json` | `psql -c "DROP TABLE users;"` | `deny` |

## Positions

- **Port the four guard skills as-is.** Rejected: `hooks:` in SKILL.md
  frontmatter is Claude-Code-only, and `freeze`'s directory boundary duplicates
  what the shared contract already scopes. Only the pattern list survives the
  move.
- **Keep `freeze`'s edit-boundary mechanism too.** Rejected: it stored the
  boundary in `~/.gstack/freeze-dir.txt` and enforced per-host. The shared
  contract is the right owner for a scoped-edit feature, and no one used the
  gstack one — telemetry recorded zero invocations in two months.
