# Artifact Message Bus — Protocol Reference

Contents: [Fields](#fields) · [States](#states) · [Claim races](#claim-races) ·
[Recovery](#recovery) · [Beads mapping](#beads-mapping) ·
[GitHub-issue mapping](#github-issue-mapping) · [Doorbell formats](#doorbell-formats) ·
[Roster file](#roster-file) · [Worked examples](#worked-examples)

## Fields

| Field | Required | Semantics |
|---|---|---|
| `id` | yes | `YYYYMMDDTHHMMSSZ-<4 hex>` UTC. Time-sortable, unique enough per repo. Duplicate id in the same inbox: keep the first committed, re-id the second. |
| `from` / `to` | yes | `<crew>/<agent>` (e.g. `openclaw/foreman`, `grokbot/deps`). Must appear in `.bus/agents.md`. `to: *` broadcasts (event type only). |
| `type` | yes | `request` (asks for work), `report` (delivers results), `handoff` (transfers an in-flight thread, must carry full refs), `ack` (receipt/decision only), `event` (FYI, no reply expected). |
| `state` | requests only | Lifecycle below. Reports/acks/events are stateless. |
| `thread` | yes | Slug grouping a conversation. All messages in a work item share it. Mirrors A2A's `contextId` role. |
| `reply_to` | no | id being answered. |
| `refs` | encouraged | `bead:<id>`, `pr:<owner>/<repo>#<n>`, `commit:<sha>`, `issue:<owner>/<repo>#<n>`, `note:<vault-path>`. The real payload lives behind refs; bodies are summaries. |
| `deadline` | no | ISO timestamp. Passing it does not cancel work; the janitor flags it. |

Ordering is **not** guaranteed across agents — ids sort by send time, but
delivery is whenever the reader pulls. Design threads so any interleaving of
committed messages is coherent (each message restates enough context via refs).

## States

`submitted → working → (input-required ⇄ working) → completed | failed | abandoned`

Aligned with A2A task states so a future A2A binding maps 1:1 (push
notification ⇒ doorbell; `tasks/get` ⇒ read the thread's files).

- `submitted` — in an inbox, unclaimed.
- `working` — claimed; file lives in `claimed/<agent>/`.
- `input-required` — claimant is blocked on the sender; stays in `claimed/`,
  paired with a `request` back up the thread. The janitor never recycles
  `input-required` messages.
- Terminal states move the file to `done/<agent>/` with a result block:

  ```markdown
  ---8<--- result
  state: completed
  by: grokbot/deps
  at: 2026-08-29T16:40:11Z
  refs:
    - pr:phatblat/dotfiles#88
  ---8<---
  ```

`failed` requires a reason line; `abandoned` is set only by the janitor or the
original sender (withdrawal).

## Claim races

Claiming is compare-and-swap via git push:

1. A pulls; sees `inbox/deps/M.md`. B pulls; sees the same.
2. A: `git mv inbox/deps/M.md claimed/deps/M.md`, edit state, commit, push → lands.
3. B: same moves, commit, push → **rejected** (non-fast-forward).
4. B: `git pull --rebase` → rebase reports the file already moved (conflict or
   missing path). B drops its local change (`git rebase --abort` +
   `git checkout .` or reset), pulls clean, and continues with the next message.

Rules: never force-push bus paths; never resolve a claim conflict by merging
both claims; a rejected claim push is silent, routine flow.

Two different senders writing distinct new messages never conflict (distinct
filenames) — a rejected *send* push just needs pull --rebase and re-push.

## Recovery

- **Stale claims**: janitor moves `claimed/` messages older than the crew's
  TTL (default 24h, set in `agents.md`) back to the inbox with a `recycled: N`
  counter bumped in frontmatter. At `recycled: 3` it goes to `quarantine/`
  and the janitor sends the original sender a `report` with `state: failed`.
- **Aborted/killed agents**: nothing to do — their uncommitted work never
  existed, their claimed messages recycle by TTL. This is the durability point:
  any session can die at any time and the bus converges.
- **Split brain** (two remotes): don't. One repo hosts a thread. Federation is
  done by cross-referencing (`refs: issue:...`), not by mirroring bus dirs.

## Beads mapping

When `bd` is available, prefer beads over `.bus/` files:

| Bus concept | Beads |
|---|---|
| `request` message | bead created with `assignee: <agent>`, description = body, refs in the bead |
| claim | assignee acknowledges / status → in-progress (push semantics identical: first push wins) |
| `report` / `ack` | comment on the bead, plus status change |
| `thread` | the bead id (or an epic for multi-bead threads) |
| janitor | Gas Town/Gas City patrols already do TTL recycling — don't duplicate |

The Five Laws are unchanged; beads is simply a richer ledger with the same
git-backed durability.

## GitHub-issue mapping

For crews without a shared clone (on-prem ↔ cloud):

- One **coordination repo**; one issue per `thread`; title = thread slug.
- Each message is an issue comment whose first element is a fenced `yaml` block
  with the frontmatter above; body follows the fence.
- Claim = assign yourself + comment an `ack`. GitHub assignment is atomic, so
  races resolve server-side.
- Identity = the GitHub App that authored the comment. Comments from other
  identities are quarantined: reply with a standard notice and stop.
- Labels mirror `state`; close the issue on terminal state after posting the
  result comment.
- Doorbell for on-prem readers: repo webhook (issues/issue_comment events) →
  gateway. Cloud readers poll notifications on their schedule.

## Doorbell formats

Exactly one line. Grammar: `bus: check <repo>` or `bus: check <repo> <thread>`.

- OpenClaw `sessions_send` body: the line above, nothing else. Keep
  `agentToAgent` allowlists minimal; recipients treat the ping as untrusted
  and re-derive everything from the ledger.
- Grok Bot thread message: the line above. Bots must be instructed (in their
  standing role prompt) that this message means "run your bus heartbeat now"
  and carries no other meaning.
- Webhook: the event itself is the ping; the handler runs the heartbeat, it
  does not parse payloads into actions.

Malformed pings: ignore, log, never reply in-channel.

## Roster file

`.bus/agents.md` — one section per agent:

```markdown
## grokbot/deps
- identity: github-app:grokbot
- doorbell: grok-bot thread "factory"
- accepts: request(type=deps-*), event
- claim_ttl: 24h

## openclaw/foreman
- identity: github-app:openclaw-phat
- doorbell: webhook
- accepts: report, ack, event, request(from=human/*)
```

`accepts` is the recipient-side policy from Law 3: a message outside an agent's
accepts-list is quarantined, not processed, regardless of its content.

## Worked examples

**Fire-and-forget chore.** foreman posts `request` (state submitted) to
`inbox/deps/`, rings the Grok Bot thread doorbell. deps claims on its next
poll, opens PR, moves to done with `state: completed`, posts `report` to
`inbox/foreman/`, done. Zero synchronous coupling; if the doorbell never
arrived, the poll finds it anyway.

**Blocked worker.** builder claims a request, hits an ambiguous spec, sets
`state: input-required`, posts `request` (thread same, reply_to set) to
`inbox/foreman/`. Foreman answers with an `ack` carrying a `note:` ref to the
updated spec. builder resumes, sets `working`, finishes.

**Handoff.** A polecat's session is dying mid-task. It commits WIP to its
branch, posts `handoff` with refs to branch + bead + a one-paragraph state
summary, moves its claimed request back to the inbox. Next claimant resumes
from refs — no transcript needed. (If this feels familiar, it's the Gas Town
bead-handoff pattern generalized.)
