# Allow `rm` under chosen roots without a prompt

Priority: Unprioritized

## Problem

`rm` prompts on every harness that has a prompt rule (`rm *` in omp's
`bash.patterns`, `"rm *": "ask"` in opencode), including the routine case of
an agent deleting its own scratch files under `/tmp`. On 2026-10-17 a
`/tmp`-only carve-out was hand-written into `~/.omp/agent/config.yml` as
thirteen ordered glob rules (prompts for `..`, `~`, `$`, backticks, and extra
arguments first, then narrow allows for `rm [flags] /tmp/<one path>`). It is
not in the shared policy, so `just harness-perms-apply` overwrites it and
opencode never gets it.

Glob matchers cannot say "every argument is under the root", and the
harnesses differ: omp is ordered first-match, opencode is last-match,
Claude's `Bash(...)` rules are prefix globs. Rendering one intent into three
matchers needs the semantics of each to be verified, not assumed.

## Outcome

An `[approval.rm]` table in the ness policy file (roots, allowed flag sets)
that `harness_policy.py` renders into each harness that can express it, with
a documented statement of what each rendering does and does not guarantee.
`rm` under a listed root runs without a prompt; `rm` anywhere else, or with
`..`, expansions, or more than one path, still prompts. The ness guard's own
`rm -rf <absolute>` deny is unchanged by this: the carve-out is approval, not
guard policy.

## Notes

- Deferred from
  [2026-10-17-ness-policy-as-data](../decisions/2026-10-17-ness-policy-as-data.md),
  which it depends on.
- The thirteen-rule omp shape from 2026-10-17 is a working starting point for
  the omp rendering.
- `ness policy check` could reject a `[approval.rm]` root that is not an
  absolute path or that is `/`.
