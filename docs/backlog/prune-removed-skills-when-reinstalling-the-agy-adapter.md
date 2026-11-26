# Prune removed skills when reinstalling the agy adapter

Priority: Low

## Problem

`agy plugin install` copies the generated adapter over the installed copy without deleting files the adapter no longer has. The 2026-11-26 audit found `git-commit` still installed 16 days after `3d2e055` removed its wrapper, and `agy-plugins.lock.json` recorded 31 skills against 32 installed. Any skill later removed from the adapter stays loadable in Antigravity the same way.

## Outcome

`just agy-plugins-update` leaves the installed copy identical to the generated adapter: `diff -rq` between the two prints nothing.

## Notes

- The install path is `cmd_install()` in `scripts/agy-plugins.py`.
- Manual workaround: `agy plugin uninstall shared-agent-harness`, then `just agy-plugins-update`.
