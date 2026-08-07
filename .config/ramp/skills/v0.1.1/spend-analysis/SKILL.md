---
name: ramp-spend-analysis
area: Cards and Spend
supported_surfaces: [cli, mcp]
description: |-
  Analyze spend by vendor, category, or team over a date range. Pulls card transactions
  and bill payments, aggregates totals, and produces summary tables.
  Use when: 'how much did we spend on', 'vendor spend', 'SaaS review', 'spend report',
  'inference costs', 'total spend', 'spend by vendor', 'spend analysis',
  'pull transactions for', 'cost breakdown'.
  Do NOT use for: approving transactions (use ramp-approval-dashboard), uploading receipts
  (use ramp-receipt-compliance), or verifying a single bill payment (use ramp-payment-lookup).
---

## Non-Negotiables

- **Pass `--rationale` on every command** — it is a required field on these agent-tools (a non-empty string, max 1024 chars). With `--json`, supply it as a `"rationale"` key in the body. Omitting it returns `HTTP 422 (DEVELOPER_INVALID_SCHEMA)`, in both agent and human modes.
- Always query both **transactions** and **bills** for complete vendor spend. Card charges and bill payments are separate resources — there is no unified spend endpoint.
- Pass `--agent` for machine-readable JSON output on all commands.
- Handle amount format differences: transactions use strings (`"$1,048.25"`, `"-$259.49"`), bills use numbers (`15000`), PO amounts use numbers. Reimbursement amounts are in dollars.
- Paginate until `next_page_cursor` is null — a single page may not return everything.
- Flag vendor name variants explicitly (e.g., "Delta Air Lines" vs "Delta Airlines") — the API does not normalize.
- Negative transaction amounts are refunds. Include them in totals but call them out.

## Workflow

### Step 1: Pull card transactions

For each vendor (or all vendors if doing a broad analysis):

```bash
ramp transactions list \
  --transactions_to_retrieve all_transactions_across_entire_business \
  --reason_memo_merchant_or_user_name_text_search "<vendor>" \
  --from_date <YYYY-MM-DD> \
  --to_date <YYYY-MM-DD> \
  --include_count \
  --page_size 200 \
  --agent --rationale "List the user's transactions"
```

If `next_page_cursor` is not null, paginate:

```bash
ramp transactions list \
  --transactions_to_retrieve all_transactions_across_entire_business \
  --reason_memo_merchant_or_user_name_text_search "<vendor>" \
  --from_date <YYYY-MM-DD> \
  --to_date <YYYY-MM-DD> \
  --page_size 200 \
  --next_page_cursor "<cursor>" \
  --agent --rationale "List the user's transactions"
```

**For broad analysis (all vendors):** Omit `--reason_memo_merchant_or_user_name_text_search` to pull all transactions, then group client-side.

### Step 2: Pull bill payments

For a specific vendor:

```bash
ramp bills search --query "<vendor>" --include_paid --limit 50 --agent --rationale "Search bills for the user"
```

For broad analysis (all vendors):

```bash
ramp bills list --include_paid --limit 50 --agent --rationale "List bills for the user"
```

Repeat either with `--page_cursor` if `next_page_cursor` is not null.

**Note:** `bills search` has no date range filter and returns `due_date` but not `payment_date`. For date-bounded actual spend, drill into paid bills with `ramp bills get <id> --agent` to get `payment_date`, then filter by that. If drilling into every bill is impractical, filter by `due_date` but label the result as "bills due in period" rather than "spend in period." Bills with `payment_status: "OPEN"` are unpaid — report them separately as commitments.

### Step 3: Parse and aggregate

#### Transaction amounts (strings → numbers)

```bash
# Sum a single vendor's transactions
... | jq '[.data[0].transactions[].amount | gsub(","; "") | if startswith("-$") then ltrimstr("-$") | tonumber | (. * -1) elif startswith("$") then ltrimstr("$") | tonumber else tonumber end] | add'
```

#### Bill amounts (already numeric, filter to paid only for actual spend)

```bash
... | jq '[.data[0].bills[] | select(.payment_status == "PAID") | .amount] | add'
```

#### Multi-vendor table with pagination

Fetch all pages first, then aggregate. Write only the minimum fields needed into
a **fresh per-run directory** (`mktemp -d`) — never a fixed path or glob shared
across runs, or stale pages from a previous or concurrent analysis get silently
included in the totals. These files can contain sensitive spend data: do not
commit or upload them, redact values before any user-approved sharing, and
delete the directory as soon as the analysis is complete. The loop continues
until `next_page_cursor` is null:

```bash
run_dir=$(mktemp -d /tmp/spend_analysis.XXXXXX)

# Page 1
ramp transactions list \
  --transactions_to_retrieve all_transactions_across_entire_business \
  --from_date 2026-01-01 --page_size 200 --include_count --agent \
  --rationale "List the user's transactions" \
  > "$run_dir/txns_page1.json"

# Page 2+ (repeat until next_page_cursor is null)
ramp transactions list \
  --transactions_to_retrieve all_transactions_across_entire_business \
  --from_date 2026-01-01 --page_size 200 --include_count --agent \
  --next_page_cursor "<cursor from previous page>" \
  --rationale "List the user's transactions" \
  > "$run_dir/txns_page2.json"
```

Then merge all pages from this run's directory and build the vendor table:

```bash
jq -s -r '
  [.[].data[0].transactions[] |
    {merchant: .merchant_name,
     amt: (.amount | gsub(","; "") |
       if startswith("-$") then ltrimstr("-$") | tonumber | (. * -1)
       elif startswith("$") then ltrimstr("$") | tonumber
       else tonumber end)}]
  | group_by(.merchant)
  | map({vendor: .[0].merchant, total: (map(.amt) | add), count: length})
  | sort_by(-.total)
  | .[] | "\(.vendor)\t$\(.total)\t(\(.count) txns)"
' "$run_dir"/txns_page*.json
```

Clean up with `rm -rf "$run_dir"` when the analysis is done.

### Step 4: Present results

Format as a clear table:

```
Vendor Spend: 2026-01-01 to 2026-04-01

Vendor              Card Txns    Bills       Total
─────────────────────────────────────────────────
Figma               $24.00       $0.00       $24.00       (3 card txns)
Delta Airlines      $3,663.73    $0.00       $3,663.73    (5 card txns, 2 merchant name variants)
AWS                 $12,450.00   $8,200.00   $20,650.00   (8 card txns, 2 bills)

Total: $24,337.73
```

Call out:
- **Vendor name variants** found (e.g., "Delta Air Lines" + "Delta Airlines")
- **Refunds** included in the totals
- **Bills vs transactions** breakdown if both exist for a vendor
- **Pagination** — whether all results were captured or if there are more pages

## Fields Available

### From `transactions list`

| Field | Description |
|---|---|
| `transaction_uuid` | Transaction UUID (use for deduplication) |
| `merchant_name` | Merchant name (not normalized) |
| `amount` | Formatted string (`"$8.00"`, `"-$259.49"`, `"$1,048.25"`) |
| `transaction_time` | ISO 8601 timestamp |
| `spent_by_user` | Employee name |
| `merchant_category` | Category (e.g., "SaaS / Software", "Airlines") |
| `reason_or_justification` | Memo / reason |
| `spend_allocation_name` | Fund / budget name |
| `transaction_link` | Direct link to transaction in Ramp UI |

### From `bills search`

| Field | Description |
|---|---|
| `id` | Bill UUID |
| `vendor_name` | Payee name |
| `amount` | Numeric (dollars) |
| `invoice_number` | Vendor invoice number |
| `payment_status` | Payment state |
| `memo` | Bill description |

## Multi-Vendor Queries

For SaaS reviews or inference spend monitoring, run vendors in parallel:

```bash
# Run these concurrently
ramp transactions list --transactions_to_retrieve all_transactions_across_entire_business \
  --reason_memo_merchant_or_user_name_text_search "Figma" --from_date 2026-01-01 --include_count --agent --rationale "List the user's transactions"

ramp transactions list --transactions_to_retrieve all_transactions_across_entire_business \
  --reason_memo_merchant_or_user_name_text_search "Anthropic" --from_date 2026-01-01 --include_count --agent --rationale "List the user's transactions"

ramp transactions list --transactions_to_retrieve all_transactions_across_entire_business \
  --reason_memo_merchant_or_user_name_text_search "OpenAI" --from_date 2026-01-01 --include_count --agent --rationale "List the user's transactions"
```

**Tip:** For vendors with known name variants, run multiple searches and deduplicate by `transaction_uuid`:
- "AWS" and "Amazon Web Services"
- "Delta Air Lines" and "Delta Airlines"

## Vendor Name Variant Detection

The API does not normalize merchant names. Common variants to watch for:

| Vendor | Possible variants |
|---|---|
| AWS | "AWS", "Amazon Web Services", "Amazon.com Services" |
| Delta | "Delta Air Lines", "Delta Airlines" |
| Google | "Google Cloud", "Google", "GCP" |

When running broad analysis (all transactions), group results and flag merchants with similar names. The agent should suggest merges.

## Example Session

```
User: How much have we spent on Figma this year?

Agent: Let me pull both card transactions and bills.
> ramp transactions list --transactions_to_retrieve all_transactions_across_entire_business \
>   --reason_memo_merchant_or_user_name_text_search "Figma" \
>   --from_date 2026-01-01 --include_count --agent --rationale "List the user's transactions"
> ramp bills search --query "Figma" --include_paid --limit 50 --agent --rationale "Search bills for the user"

Figma spend YTD (2026-01-01 to today):

  Card transactions: 3 totaling $24.00
    $8.00  Michael Scott  2026-03-17  "Trial spend for one Sales user"
    $8.00  Michael Scott  2026-03-17  "Trial spend for one Sales user"
    $8.00  Michael Scott  2026-03-17  "Trial spend for one Sales user"

  Bills: 0

  Total: $24.00

Note: There's also an open PO for Figma Enterprise ($150,042.75, PO #9880)
if you want to check commitment vs actual spend.

User: Give me a full SaaS vendor breakdown

Agent: Pulling all transactions and grouping by merchant...
> ramp transactions list --transactions_to_retrieve all_transactions_across_entire_business \
>   --from_date 2026-01-01 --page_size 200 --include_count --agent --rationale "List the user's transactions"

SaaS Vendor Spend YTD:

Vendor              Total         Txns
────────────────────────────────────────
Brown Group         $50,000.00    1
Cochran Ltd         $21,500.00    1
Goody               $9,119.13     3
Morris-Allen        $8,900.00     1
Figma               $24.00        3

⚠ Vendor name variants detected:
  "Delta Air Lines" (2 txns) + "Delta Airlines" (5 txns) — likely same vendor

Note: This only includes card transactions. Bill payments are separate —
want me to also search bills for these vendors?
```

## When NOT to Use

- **Verifying a single payment** — use `ramp-payment-lookup`
- **Approving transactions** — use `ramp-approval-dashboard`
- **Receipt or memo cleanup** — use `ramp-receipt-compliance` or `ramp-transaction-cleanup`
- **Detailed PO status** — run `ramp purchase_orders get` directly

## Gotchas

| Issue | Fix |
|---|---|
| Transaction amounts are strings (`"$1,048.25"`) | Strip `$` and `,` before summing. Handle `-$` prefix for refunds. |
| Bill amounts are numeric (dollars) | Use directly — no parsing needed |
| `--transactions_to_retrieve` is required | Always include it. Use `all_transactions_across_entire_business` for company-wide analysis. |
| Search text must be ≥3 characters | "AI" won't work — use full vendor name |
| `bills search` has no date filter | Search returns `due_date` not `payment_date`. Use `bills get` for actual payment dates. Use `bills list` for no-query pulls. |
| Vendor name variants not normalized | Run multiple searches for known variants. Dedupe by `transaction_uuid`. |
| Pagination ceiling | `--page_size 200` is accepted. Still check `next_page_cursor`. |
| No unified spend endpoint | Query transactions and bills separately, then merge the results. |
| `--include_count` only on transactions | Bills search returns `total_found` automatically. |
| Something broken? | With the user's consent, run `ramp feedback "<user-approved message>"`. This sends only that message to Ramp support; omit secrets and diagnostic artifacts. |
