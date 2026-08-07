---
name: ramp-manage-bills
area: Bill Pay
supported_surfaces: [cli, mcp]
description: |-
  Search, inspect, and manage vendor bills and invoices. Use when:
  'find a bill', 'show me pending bills', 'bill details', 'look up a bill',
  'draft bill details', 'bill attachments', 'what bills need my approval'.
  Do NOT use for: approving bills (use ramp-approval-dashboard), uploading vendor
  documents (use ramp-vendor-document-upload), or card transaction management
  (use ramp-transaction-cleanup).
---

# Manage Bills

Search, inspect, and review vendor bills — submitted, draft, and pending approval — using the `ramp` CLI.

## Non-Negotiables

- **Pass `--rationale` on every command** — it is a required field on these agent-tools (a non-empty string, max 1024 chars). With `--json`, supply it as a `"rationale"` key in the body. Omitting it returns `HTTP 422 (DEVELOPER_INVALID_SCHEMA)`, in both agent and human modes.
- **Deep links**: If the response contains a `bill_url` field, always include it when presenting bill details — it lets the user click through to the Ramp web app. If the field is absent, direct the user to the Ramp bills page instead. Use the URL matching the active CLI environment: `https://app.ramp.com/bills` for production or `https://demo.ramp.com/bills` for sandbox. Run `ramp env` to check the current environment if unsure.
- Bill amounts are in **cents**. Divide by 100 for display (e.g., `350000` → `$3,500.00`).
- Bill IDs are UUIDs. Always confirm the correct bill before acting on it.
- Use `--agent` for machine-readable JSON output when parsing results programmatically.
- These are **read-only** commands. For approvals, use `ramp-approval-dashboard`. For write operations on drafts, use draft bill commands when available.
- When the agent cannot complete an action (e.g., editing complex bill fields, approving a bill), hand off to the user via the `bill_url` deep link (if present) or the Ramp bills page.

## Workflow

### Step 1: Find bills

Start by searching or listing bills to locate the ones the user needs.

```bash
# Search by vendor name, invoice number, or payment ID
ramp bills search --query "Acme Corp" --agent --rationale "Search bills for the user"

# List all bills (no query required)
ramp bills list --agent --limit 20 --rationale "List bills for the user"

# Paid bills are included by default; pass --no-include_paid to exclude them
ramp bills search --query "UPS" --agent --rationale "Search bills for the user"

# Paginate through results
ramp bills search --query "Acme" --page_cursor "{cursor_from_previous_response}" --agent --rationale "Search bills for the user"
```

If the response includes a `bill_url` field on each bill, present it alongside the bill summary.

### Step 2: Get bill details

Once you have a bill ID, pull comprehensive details:

```bash
# Full bill details (submitted bills only)
ramp bills get --bill_id "{bill_id}" --agent --rationale "Review bill details"

# Draft bill details (not yet submitted)
ramp bills draft --bill_id "{bill_id}" --agent --rationale "Draft the bill"
```

The `get` response includes: amount, currency, vendor info, approval status, payment status, due date, invoice number, line items, accounting field codings, and more. Use this as your primary tool for investigating a bill — it covers status, amount breakdowns, and metadata in a single call.

If the response includes a `bill_url` field, it is a direct link to the bill in the Ramp web app. The URL routes to the correct page based on bill status (drafts, approvals, or paid).

### Step 3: Retrieve bill attachments

```bash
# Get invoice file attachments
ramp bills attachments --bill_id "{bill_id}" --agent --rationale "Fetch bill attachments"
```

### Step 4: Pending approvals

```bash
# Bills waiting for the current user's approval
ramp bills pending --agent --limit 20 --rationale "Review bills pending approval"

# Paginate through pending bills
ramp bills pending --page_cursor "{cursor}" --agent --rationale "Review bills pending approval"
```

## How to Present Results

### Bill search results

Include the deep link on each row when present:

```
Found 3 bills matching "Acme Corp":

  $3,500.00  Acme Corp       INV-2024-001  Approved   Due 2026-04-15  → <bill_url>
  $1,200.00  Acme Corp       INV-2024-002  Pending    Due 2026-04-30  → <bill_url>
  $  850.00  Acme Corp       INV-2023-012  Paid       Paid 2026-03-01 → <bill_url>
```

### Bill details

When showing bill details, include the deep link if available:

```
Bill: INV-2024-001
Vendor: Acme Corp
Amount: $3,500.00 USD
Status: Approved — awaiting payment
Due: 2026-04-15
Created: 2026-03-20
Memo: Q1 office supplies
Open in Ramp: <bill_url>          ← include only if bill_url is in the response

Line items:
  1. Printer paper (500 reams)     $2,000.00
  2. Toner cartridges (50 units)   $1,500.00
```

### Pending approvals

```
5 bills pending your approval ($12,450.00 total):

  $5,000.00  HighSpot        INV-4401    Due 2026-03-28  → <bill_url>
  $3,200.00  Cometeer        INV-882     Due 2026-04-01  → <bill_url>
  $2,500.00  UPS Store       INV-7722    Due 2026-04-05  → <bill_url>
  $1,200.00  Slack           INV-9001    Due 2026-04-10  → <bill_url>
  $  550.00  Canva           INV-3344    Due 2026-04-12  → <bill_url>
```

If `bill_url` is not present in the response, omit the link column — do not fabricate URLs.

## Deep Link Handoff

When the agent cannot perform an action on a bill — such as approving, editing payment details, or modifying line items — direct the user to complete the action in the Ramp web app:

- If `bill_url` is present in the response, use it:
  ```
  I can't approve bills via the CLI. You can approve this bill directly in Ramp:
    $3,500 HighSpot Invoice #1234 → <bill_url>
  ```
- If `bill_url` is not present, direct the user to the environment-appropriate Ramp bills page (`https://app.ramp.com/bills` for production, `https://demo.ramp.com/bills` for sandbox):
  ```
  I can't approve bills via the CLI. You can find this bill in Ramp at:
    https://app.ramp.com/bills        ← use https://demo.ramp.com/bills for sandbox
  ```

Always prefer the `bill_url` from the API response when available — the response URL accounts for bill status and environment. Never fabricate a deep link URL.

Common handoff scenarios:
- **Bill approval** — not available via CLI
- **Editing payment method or schedule** — requires the bill pay UI
- **Adding or editing line items** — complex edits are best done in the app
- **Uploading invoice attachments** — use the Ramp web app

## When NOT to Use

- **Approving or rejecting bills** — use `ramp-approval-dashboard`
- **Uploading vendor documents** (W-9, contracts) — use `ramp-vendor-document-upload`
- **Transaction receipts** — use `ramp-receipt-compliance`
- **Editing transaction memos or categories** — use `ramp-transaction-cleanup`
- **Making payments or releasing funds** — not available via CLI

## Gotchas

| Issue | Fix |
|---|---|
| Bill amounts are in cents | Divide by 100 for display |
| Paid bills are included by default | Pass `--no-include_paid` to exclude them |
| `search` returns only submitted bills | Use `draft` for provisional/unsubmitted bills |
| `get` returns 404 for a draft bill | Use `ramp bills draft --bill_id` instead |
| Pagination cursor is an encrypted token | Pass the exact `next_page_cursor` value from the response; never fabricate one |
| `bill_url` may be absent or null | Fall back to the environment-appropriate bills page (`app.ramp.com/bills` or `demo.ramp.com/bills`) — never fabricate a deep link |

## Example Session

```
User: What bills do we have from Acme?

Agent: Let me search for Acme bills.
> ramp bills search --query "Acme" --agent --rationale "Search bills for the user"

Found 2 bills from Acme Corp:
  $3,500.00  INV-2024-001  Approved   Due 2026-04-15  → <bill_url>
  $1,200.00  INV-2024-002  Pending    Due 2026-04-30  → <bill_url>

User: Show me the details on the first one.

Agent: > ramp bills get --bill_id "abc-123-def" --agent --rationale "Show details for the Acme bill the user selected"

Bill: INV-2024-001
Vendor: Acme Corp
Amount: $3,500.00 USD
Status: Approved — awaiting payment
Due: 2026-04-15
Memo: Q1 office supplies
Open in Ramp: <bill_url>
2 line items, 1 invoice attachment

User: Are there any attachments?

Agent: > ramp bills attachments --bill_id "abc-123-def" --agent --rationale "List attachments on the Acme bill for the user"

1 invoice attachment:
  acme-invoice-2024-001.pdf (uploaded 2026-03-20)

User: What bills need my approval?

Agent: > ramp bills pending --agent --rationale "List bills awaiting the user's approval"

3 bills pending your approval ($6,700.00 total):
  $3,200.00  Cometeer    INV-882     Due 2026-04-01  → <bill_url>
  $2,500.00  UPS Store   INV-7722    Due 2026-04-05  → <bill_url>
  $1,000.00  Canva       INV-3344    Due 2026-04-12  → <bill_url>

To approve these, use the ramp-approval-dashboard skill.
```

## Command Reference

| Command | Description | Key params |
|---|---|---|
| `ramp bills search` | Search bills by vendor, invoice number, or payment ID | `--query`, `--limit`, `--include_paid`, `--page_cursor` |
| `ramp bills list` | List bills without a search query | `--limit`, `--include_paid`, `--page_cursor` |
| `ramp bills get` | Full details for a submitted bill | `--bill_id` (required) |
| `ramp bills draft` | Details for an unsubmitted draft bill | `--bill_id` (required) |
| `ramp bills attachments` | Invoice file attachments | `--bill_id` (required) |
| `ramp bills pending` | Bills awaiting your approval | `--limit`, `--page_cursor` |
