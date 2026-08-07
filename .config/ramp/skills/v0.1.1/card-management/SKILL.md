---
name: ramp-card-management
area: Cards and Spend
supported_surfaces: [cli, mcp]
description: |-
  Inspect a user's card/fund status, then activate or lock/unlock a card from
  the terminal. Use for card status, card lock questions, physical card
  activation, and card lock/unlock actions.
---

# Card Management

## Non-Negotiables

- To inspect card/fund status, use `ramp funds list`. The current generated
  spec no longer exposes `ramp cards list`.
- Use `--state ACTIVE` when the user asks for active cards/funds.
- Use `--include_lock_info` when the user asks why a card or fund is locked.
- Use `--include_members` when the user asks who has access to a fund/card.
- Pass `--agent` for machine-readable JSON output whenever you need to count
  or inspect returned fields programmatically.
- Report the fields returned by the API. Do not invent card lifecycle states.

## Workflow

### Step 1: Inspect card/fund status

```bash
ramp funds list --funds_to_retrieve MY_FUNDS --rationale "inspect the user's card and fund status" --agent
```

In `--agent` mode the response is wrapped in the standard envelope. Fund/card
records live in the nested array at `.data[0].funds[]`.

Admins and managers can target another employee's funds/cards by passing that
user's UUID. Resolve the UUID first, then pass it through `--user_uuids`.

```bash
ramp users org-chart --rationale "find the employee's user UUID" --agent
ramp funds list --user_uuids '["USER_UUID"]' --include_lock_info --rationale "inspect this employee's card and fund status" --agent
```

### Step 2: Count or filter by state

Count active card/fund contexts:

```bash
ramp funds list --funds_to_retrieve MY_FUNDS --state ACTIVE --rationale "count active card and fund contexts" --agent | jq '.data[0].funds | length'
```

List active card/fund context names:

```bash
ramp funds list --funds_to_retrieve MY_FUNDS --state ACTIVE --rationale "list active card and fund contexts" --agent | jq -r '.data[0].funds[] | .name'
```

### Step 3: Inspect lock or access details

When debugging lock questions, add lock info and inspect the `lock` and
`member_locks` fields. When debugging access questions, add members and inspect
the `members` field.

```bash
ramp funds list --funds_to_retrieve MY_FUNDS --include_lock_info --rationale "inspect fund and card lock details" --agent
```

### Step 4: Activate or lock a card

Activate a physical card by its last four digits:

```bash
ramp cards activate --last_four 1234 --rationale "activate the user's new physical card" --agent
```

Lock or unlock a card by its id. The id is a required positional argument:

```bash
ramp cards lock 7f3c0d2a-9b1e-4a55-8c21-0e9d6b2f4a10 --action lock --rationale "user lost their card" --agent
ramp cards lock 7f3c0d2a-9b1e-4a55-8c21-0e9d6b2f4a10 --action unlock --rationale "user found their card" --agent
```

The same write tools are also available under `funds` using their full command
names, for example `ramp funds activate` and `ramp funds lock-or-unlock-card`.

## Fields To Inspect

| Field | Meaning |
|---|---|
| `id` | Fund/card context UUID |
| `name` | Display name |
| `state` | Current fund/card context state when returned |
| `lock` | Fund-level lock information when `--include_lock_info` is set |
| `member_locks` | Member-specific lock information when returned |
| `members` | Users with access when `--include_members` is set |
| `allocation_url` | Ramp web deep link when returned |

## Example Session

```
User: Why can't I use my card?

Agent: > ramp funds list --funds_to_retrieve MY_FUNDS --include_lock_info --rationale "inspect the user's card and fund lock status" --agent

Agent: Your card/fund context is locked because the API returned a lock entry
requiring missing policy items.
```

## Gotchas

| Issue | Fix |
|---|---|
| `ramp cards list` is not available in the current spec | Use `ramp funds list` for card/fund status |
| Need only active cards/funds | Add `--state ACTIVE` |
| Need card lock details | Add `--include_lock_info` |
| Need card access/member details | Add `--include_members` |
| Something broken? | With the user's consent, run `ramp feedback "<user-approved message>"`. This sends only that message to Ramp support; omit secrets and diagnostic artifacts. |
