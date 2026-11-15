---
name: "cmux-workspace-status"
description: "Set the cmux workspace to done with `cmux workspace status set done`. Use at the end of a verified session in a cmux terminal; skip when blocked, handed off, or nothing changed."
---

# cmux-workspace-status

cmux shows a status lane per workspace in its left sidebar. The lane is normally inferred from live signals (agent needs input > agent running > open PR > all PRs merged or closed > dirty git tree > todo), so a finished session whose tree is still dirty keeps reading as working. Pinning `done` is what makes the sidebar reflect a reached goal.

## When to invoke

Invoke once, immediately before the final response of a session in which all of these hold:

- the user's goal was reached
- the change was verified (tests, smoke run, or the explicit check the session agreed on)
- nothing is left for the user to act on

Do not invoke when:

- the session ended blocked, or is waiting on user input, review, or an external service
- the work was handed off to another agent or session
- the session only answered a question, explored, or produced a plan without applying it
- verification failed or was skipped

## Guard and command

The command targets the caller's workspace through `CMUX_WORKSPACE_ID`. Outside a cmux terminal that variable is unset and cmux falls back to whichever workspace is focused, which is the wrong one. Check first and do nothing when it is empty:

```bash
[ -n "$CMUX_WORKSPACE_ID" ] || exit 0
cmux workspace status set done
```

Expected output:

```
done
inferred: <lane>
override: done (auto-clears when inferred moves off <lane>)
```

## Notes

- The pin releases itself: cmux drops the override as soon as the inferred lane moves off the lane it was inferred at. There is no unpin step and no cleanup.
- One attempt only. If the command exits non-zero (cmux not running, socket unavailable, no `cmux` on PATH), ignore it. Do not retry, do not target another workspace, and do not mention it in the final response unless the user asked about workspace status.
- `set` accepts `todo`, `working`, `needs-attention`, `review`, `done`, plus `auto` and `none` to clear a pin. Only `done` belongs in this flow; clear a premature pin by hand with `cmux workspace status set auto`.
- `cmux workspace status` with no arguments prints the effective lane, the inferred lane, and the current override — use it to confirm a pin landed.
