---
name: ramp-transaction-cleanup
area: Cards and Spend
supported_surfaces: [cli, mcp]
description: |-
  Complete missing items on your transactions — memos, accounting categories, funds,
  and attendees. Use when: 'add memo', 'categorize transactions', 'missing items',
  'transaction cleanup', 'fix my transactions', 'set tracking category',
  'assign to fund', 'bulk memo update'. Do NOT use for: receipt uploads
  (use ramp-receipt-compliance) or approvals (use ramp-approval-dashboard).
---

## Non-Negotiables

- **Pass `--rationale` on every command.** It is a required field on these agent-tools (`edit-transaction`, `get-transaction-missing-items`, `get-full-transaction-metadata`, etc.). Omitting it returns `HTTP 422 (DEVELOPER_INVALID_SCHEMA)` — see [Gotchas](#gotchas).
- Scope to the user's own transactions by default (`--transactions_to_retrieve my_transactions`).
- Show the transaction details before editing. Never blind-edit.
- For bulk edits, present the plan and confirm before executing.
- The `--user_submitted_fields` flag tracks provenance — include it to mark which fields the user explicitly provided vs agent-inferred.
- All CLI flags use **underscores**, not hyphens.

## `--rationale` is required

Every command in this skill maps to an agent-tool endpoint that **requires** a
`rationale`: a non-empty string (max 1024 chars) explaining why you are making
the call. Pass it as `--rationale "..."`, or include a `"rationale"` key in the
`--json` body. It is required for **both** agent (`--agent`) and human
(`agent=false`) invocations — omitting it is the #1 cause of `HTTP 422` errors on
these tools. The examples below all include it; keep it on every call.

## Workflow

### Step 1: Find transactions needing attention

```bash
# Transactions awaiting your action (usually means missing items)
ramp transactions list --transactions_to_retrieve my_transactions \
  --from_date {start} --state cleared --rationale "Find transactions needing cleanup" --agent --page_size 50
```

For any transaction, check what's missing:
```bash
ramp transactions missing {transaction_uuid} --rationale "Check missing items on this transaction"
```

Returns: `missing_receipt` (bool), `missing_memo` (bool), `missing_accounting_items` (array of category names).

### Step 2: Get AI-suggested memos

Before writing memos manually, check if Ramp has suggestions:
```bash
ramp transactions memo-suggestions {transaction_uuid} --rationale "Fetch AI-suggested memos"
```

Returns `memos[]` — an array of suggested memo strings based on the transaction context.

### Step 3: Edit transactions

#### Set a memo
```bash
ramp transactions edit {transaction_uuid} --memo "Q2 team offsite catering" --rationale "Add the user's memo"
```

To clear a memo, pass an empty string: `--memo ""` (note: `--rationale` itself must never be empty).

#### Assign to a fund/spend allocation
```bash
ramp transactions edit {transaction_uuid} --fund_uuid {fund_uuid} --rationale "Assign transaction to the chosen fund"
```

To find available funds:
```bash
ramp funds list --funds_to_retrieve MY_FUNDS --include_balance --rationale "List funds to assign the transaction" --agent
```

#### Set tracking categories (accounting codes)

First, get available categories and their options:
```bash
# List categories
ramp accounting categories --rationale "List tracking categories" --agent

# List options for a specific category (use UUID from above)
ramp accounting category-options {tracking_category_uuid} --rationale "List options for the tracking category" --agent --page_size 50
```

Then edit via `--json` (tracking categories aren't exposed as named flags).

**Important:** When using `--json`, you must include both `rationale` and `transaction_uuid` in the body. The `--json` flag bypasses the CLI's automatic injection of the positional arg and the `--rationale` flag, so a `--json` body without a `"rationale"` key returns `HTTP 422`.

```bash
ramp transactions edit --json '{
  "rationale": "Set the tracking category the user chose",
  "transaction_uuid": "{transaction_uuid}",
  "tracking_category_selections": [
    {
      "category_uuid": "{category_uuid}",
      "option_selection": "{option_uuid}"
    }
  ],
  "user_submitted_fields": ["tracking_category_selections"]
}'
```

Note: the field names inside `tracking_category_selections` are `category_uuid` and `option_selection` — NOT `tracking_category_uuid` / `tracking_category_option_uuid` (those are the names returned by the categories list endpoint, not the edit endpoint).

#### Set attendees
```bash
ramp transactions edit --json '{
  "rationale": "Record attendees for this expense",
  "transaction_uuid": "{transaction_uuid}",
  "attendee_selections": {
    "non_ramp_attendees": [
      {"attendee_name": "Jane Smith", "attendee_email": "jane@company.com"}
    ],
    "include_self_as_attendee": false
  },
  "user_submitted_fields": ["attendee_selections"]
}'
```

### Step 4: Handle missing receipts (hand off)

If `missing_receipt` is true, you have two options:

1. **Upload a receipt** — use the ramp-receipt-compliance skill
2. **Explain why it's missing**:
```bash
ramp transactions explain-missing {transaction_uuid} \
  --reason "Digital subscription — no receipt issued" \
  --rationale "Record why the receipt is missing"
```

Or generate a link to the missing receipt affidavit form (the user must complete it manually in the browser):
```bash
ramp transactions flag-missing {transaction_uuid} --rationale "Generate a missing-receipt affidavit link"
```

## Bulk Cleanup Workflow

For cleaning up many transactions at once:

1. Fetch all transactions in the period
2. Check `missing_items` on each (or batch-check via individual calls)
3. Group by what's missing: memo, accounting, receipt
4. Present summary: "12 transactions need memos, 5 need accounting categories, 3 need receipts"
5. For memos: fetch suggestions for each, present them, let user confirm or edit
6. For categories: if most transactions share a category, offer to bulk-apply
7. Execute edits sequentially, report progress

## Provenance Tracking

The `--user_submitted_fields` flag tells Ramp which fields the user explicitly provided. This matters for compliance — it distinguishes user intent from agent inference.

Include it when setting fields via `--json`:
```bash
ramp transactions edit --json '{
  "rationale": "Add the user's memo",
  "transaction_uuid": "{transaction_uuid}",
  "memo": "Client dinner with Acme team",
  "user_submitted_fields": ["memo"]
}'
```

Valid values: `attendee_selections`, `attendee_uuids`, `fund_uuid`, `memo`, `tracking_category_selections`.

When using named flags (`--memo`, `--fund_uuid`), provenance is tracked automatically.

## Example Session

```
User: I have a bunch of transactions that need memos

Agent: Let me check what's missing on your recent transactions.
> ramp transactions list --transactions_to_retrieve my_transactions \
>   --from_date 2026-03-01 --state cleared --rationale "Find transactions needing cleanup" --agent --page_size 50

Found 8 transactions. Checking missing items on each...
> ramp transactions missing {uuid} --rationale "Check missing items" (×8)

Summary:
  5 need memos
  2 need accounting categories
  1 needs a receipt (→ use ramp-receipt-compliance)

Let me get AI-suggested memos for the 5:
> ramp transactions memo-suggestions {uuid} --rationale "Fetch suggested memos" (×5)

Transaction                              Suggested memo
$135  Facebook Ads     2026-03-02       "Q1 paid social campaign"
$220  AWS              2026-03-05       "March infrastructure costs"
$89   Uber             2026-03-10       (no suggestion)
$450  WeWork           2026-03-12       "March coworking space"
$65   Doordash         2026-03-15       (no suggestion)

Want to accept these suggestions, edit them, or write your own?

User: Accept the suggestions for Facebook and AWS. The Uber was a client dinner ride, WeWork is fine, skip DoorDash for now.

Agent: Updating 4 transactions:
> ramp transactions edit {fb-uuid} --memo "Q1 paid social campaign" --rationale "Apply accepted memo suggestion"
> ramp transactions edit {aws-uuid} --memo "March infrastructure costs" --rationale "Apply accepted memo suggestion"
> ramp transactions edit {uber-uuid} --memo "Client dinner transportation" --rationale "Set memo from user input"
> ramp transactions edit {wework-uuid} --memo "March coworking space" --rationale "Apply accepted memo suggestion"

All 4 memos set. 2 transactions still need accounting categories.
Want to tackle those?

User: Yes, they should both be under the "Marketing" project

Agent: > ramp accounting categories --rationale "List tracking categories" --agent
> ramp accounting category-options {project-uuid} --rationale "List options for the Marketing project" --agent --page_size 50

Found "Marketing" option (uuid: mkt-123). Applying to both:
> ramp transactions edit --json '{"rationale": "Set Marketing project category", "transaction_uuid": "{uuid1}", "tracking_category_selections": [{"category_uuid": "proj-uuid", "option_selection": "mkt-123"}]}'
> ramp transactions edit --json '{"rationale": "Set Marketing project category", "transaction_uuid": "{uuid2}", "tracking_category_selections": [{"category_uuid": "proj-uuid", "option_selection": "mkt-123"}]}'

Done. 1 transaction remaining (needs receipt — use ramp-receipt-compliance when ready).
```

## When NOT to Use

- **Uploading receipts** — use ramp-receipt-compliance (handles base64 encoding, matching, bulk upload)
- **Approving or rejecting items** — use ramp-approval-dashboard
- **Company-wide spend reporting** — the CLI is scoped to your own data; use the Ramp dashboard

## Gotchas

| Issue | Fix |
|---|---|
| `HTTP 422 "API error 422: There was an error."` | You omitted `rationale`. It's a required field on these agent-tools (`DEVELOPER_INVALID_SCHEMA`) — add `--rationale "..."`, or a `"rationale"` key in the `--json` body. Required for both agent and human (`agent=false`) calls. Not a permissions problem. |
| `--dry_run` succeeds but the real call 422s | `--dry_run` only prints the body; it does not validate it. Confirm `rationale` is present before sending. |
| `amount` is a formatted string ("$135.40") | Strip "$" and "," for numeric operations |
| `--state` values are lowercase | Use `cleared`, `pending` — not uppercase |
| Tracking categories require `--json` | Named flags only cover `--memo` and `--fund_uuid`. When using `--json`, include both `rationale` and `transaction_uuid` in the body. |
| Category field names differ between endpoints | `accounting category-options` returns `tracking_category_option_uuid`, but `transactions edit` expects `category_uuid` + `option_selection` |
| `memo-suggestions` may return empty | Not all transactions have enough context for suggestions |
| `accounting category-options` paginates with integers | Unlike other endpoints, the cursor is a number, not a string |
| `--transactions_to_retrieve` is required | Always include it on `transactions list` |
| Searching for specific transactions | Use `--reason_memo_merchant_or_user_name_text_search "query"` (min 3 chars) |
| Comment on a transaction | `ramp general comment {uuid} --ramp_object_type transaction --message "text" --rationale "Add a comment for the user"` |
