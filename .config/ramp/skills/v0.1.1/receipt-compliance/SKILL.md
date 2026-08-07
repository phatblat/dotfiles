---
name: ramp-receipt-compliance
area: Cards and Spend
supported_surfaces: [cli, mcp]
description: |-
  Find your transactions missing receipts and upload them. Use when: 'missing receipts',
  'receipt compliance', 'upload receipt', 'attach receipt', 'receipt sweep',
  'transactions without receipts'. Do NOT use for memo/coding/fund cleanup
  (use ramp-transaction-cleanup) or approving transactions (use ramp-approval-dashboard).
---

## Non-Negotiables

- **Pass `--rationale` on every command** — it is a required field on these agent-tools (a non-empty string, max 1024 chars). With `--json`, supply it as a `"rationale"` key in the body. Omitting it returns `HTTP 422 (DEVELOPER_INVALID_SCHEMA)`, in both agent and human modes.
- Scope to the user's own transactions unless they explicitly request broader access.
- Never upload a receipt without confirming the match — wrong receipt on wrong transaction is worse than no receipt.
- When running in sweep mode, present the plan before uploading. Let the user confirm.
- Use `ramp transactions missing {uuid}` as the reliable check for whether a receipt is attached — it returns `missing_receipt: true/false` in real time. The `receipt_uuids` field in the list response can be used as a quick filter, but it may be stale (e.g., remaining null even after a successful upload+attach).
- Receipts must be **base64-encoded** for upload. Accepted types: PNG, JPEG, PDF, HEIC, WEBP.
- All CLI flags use **underscores**, not hyphens (e.g., `--from_date`, `--transaction_uuid`).

## Workflow

### Mode 1: Upload a specific receipt

When the user has a receipt file and wants to attach it to a transaction:

```bash
# Find the transaction
ramp transactions list --transactions_to_retrieve my_transactions \
  --from_date {date} --state cleared --agent --page_size 20 --rationale "List the user's transactions"

# Base64 encode the file (agent does this)
# For a file at /path/to/receipt.pdf:
base64 -i /path/to/receipt.pdf | tr -d '\n'

# Upload and auto-attach in one step
ramp receipts upload \
  --content_type "application/pdf" \
  --filename "receipt.pdf" \
  --file_content_base64 "{base64_string}" \
  --transaction_uuid {txn_uuid} --rationale "Upload the receipt"
```

The response returns `receipt_uuid` and `attached_to_transaction: true/false`.

If `--transaction_uuid` is omitted, the receipt is uploaded but not attached. You can attach later with:
```bash
ramp receipts attach {receipt_uuid} {transaction_uuid} --rationale "Attach the receipt to the transaction"
```

### Mode 2: Compliance sweep — find all missing receipts

```bash
ramp transactions list --transactions_to_retrieve my_transactions \
  --from_date {start} --to_date {end} --state cleared --agent --page_size 50 --rationale "List the user's transactions"
```

Filter results for transactions where `receipt_uuids` is null or empty. You can also check `missing_items` on individual transactions:

```bash
ramp transactions missing {transaction_uuid} --rationale "Check missing items on the transaction"
```

This returns `missing_receipt` (bool), `missing_memo` (bool), and `missing_accounting_items` (array).

Present results grouped by merchant:

```
Missing receipts: 8 transactions ($4,520 total)

  $1,200  United Airlines     2026-03-01
  $  800  Hilton Hotels       2026-03-03
  $  450  Uber                2026-03-05
  ...
```

### Mode 3: Upload from a directory of receipt files

When the user has a folder of receipt images/PDFs to bulk-attach:

```bash
# For each file:
# 1. Determine MIME type from extension (.pdf → application/pdf, .png → image/png, .jpg → image/jpeg)
# 2. Base64 encode: base64 -i <file> | tr -d '\n'
# 3. Match to a transaction by inferring merchant/date from filename or content
# 4. Upload with -n (dry run) first to verify

ramp receipts upload \
  --content_type "image/png" \
  --filename "uber-2026-03-01.png" \
  --file_content_base64 "{base64}" \
  --transaction_uuid {txn_uuid} -n --rationale "Upload the receipt"

# If correct, upload for real (without -n)
ramp receipts upload \
  --content_type "image/png" \
  --filename "uber-2026-03-01.png" \
  --file_content_base64 "{base64}" \
  --transaction_uuid {txn_uuid} --rationale "Upload the receipt"
```

### Mode 4: Explain why a receipt is missing

If the user doesn't have a receipt and wants to provide a reason:

```bash
ramp transactions explain-missing {transaction_uuid} --reason "Lost receipt — vendor confirmed purchase via email" --rationale "Record why the receipt is missing"
```

Or generate a link to the missing receipt affidavit form (the user must complete it manually in the browser):
```bash
ramp transactions flag-missing {transaction_uuid} --rationale "Generate a missing-receipt affidavit link"
```

## Matching Heuristics

When matching receipt files to transactions:

- **Filename patterns**: `merchant-YYYY-MM-DD.pdf`, `YYYY-MM-DD-merchant.png`, etc.
- **Amount matching**: If the receipt shows an amount, match to transactions within ±$1 at that merchant on that date.
- **Date matching**: Receipt date should be within 1-2 days of `transaction_time`.
- **One receipt per transaction**: Before each upload, re-check the live state with `ramp transactions missing {transaction_uuid}` and skip when `missing_receipt` is `false`. Do not rely on `receipt_uuids` from an earlier list response — it can be stale (see Gotchas) and would trigger a duplicate upload of a recently attached receipt.

Flag uncertain matches as "possible match — verify" rather than auto-uploading.

## MIME Type Reference

| Extension | Content type |
|---|---|
| `.png` | `image/png` |
| `.jpg`, `.jpeg` | `image/jpeg` |
| `.pdf` | `application/pdf` |
| `.heic` | `image/heic` |
| `.webp` | `image/webp` |

## Pagination

If `pagination.next_cursor` is not null in the JSON envelope, there are more results:
```bash
ramp transactions list --transactions_to_retrieve my_transactions \
  --from_date {start} --state cleared --agent --page_size 50 \
  --next_page_cursor "{cursor}" --rationale "List the user's transactions"
```

## Example Session

```
User: I have some missing receipts to clean up

Agent: Let me check your recent transactions for missing receipts.
> ramp transactions list --transactions_to_retrieve my_transactions \
>   --from_date 2026-03-01 --state cleared --agent --page_size 50 --rationale "List the user's transactions"

Missing receipts: 3 transactions ($1,870 total)

  $1,200  United Airlines     2026-03-05
  $  450  Hilton Hotels       2026-03-08
  $  220  Uber                2026-03-12

Would you like to upload receipts for any of these?

User: I have the United one, it's at ~/Downloads/united-mar5.pdf

Agent: Let me upload that receipt.
> base64 -i ~/Downloads/united-mar5.pdf | tr -d '\n'
> ramp receipts upload --content_type "application/pdf" \
>   --filename "united-mar5.pdf" \
>   --file_content_base64 "{base64}" \
>   --transaction_uuid "abc-123" -n --rationale "Upload the receipt"

Dry run looks correct — uploading to United Airlines ($1,200) on 2026-03-05.
Proceed?

User: yes

Agent: > ramp receipts upload --content_type "application/pdf" ...
Receipt uploaded and attached (receipt_uuid: def-456).
2 transactions still missing receipts. Want to continue?

User: The Uber one was a personal ride, no receipt

Agent: > ramp transactions explain-missing "xyz-789" --reason "Personal ride — no receipt" --rationale "User said the Uber charge was a personal ride with no receipt"
Done. 1 transaction remaining (Hilton Hotels, $450).
```

## When NOT to Use

- **Memo or accounting cleanup** — use ramp-transaction-cleanup
- **Approving or rejecting transactions** — use ramp-approval-dashboard
- **Company-wide spend analysis** — the CLI is scoped to your own data; use the Ramp dashboard

## Gotchas

| Issue | Fix |
|---|---|
| `amount` is a formatted string ("$135.40") | Strip "$" and "," to get numeric value for display |
| Large files may hit shell arg limits | For files >100KB, write base64 to a temp file and use `--json` with the content read from file |
| `receipts attach` may fail on some transactions | Use `receipts upload --transaction_uuid` instead (upload + attach in one step) |
| Duplicate upload risk | Re-check `ramp transactions missing {uuid}` immediately before uploading; skip when `missing_receipt` is `false`. `receipt_uuids` alone can be stale. |
| `--transactions_to_retrieve` is required | Always include it. Use `my_transactions` for personal, `all_transactions_across_entire_business` for admin scope |
| `--state` values are lowercase | Use `cleared`, `pending`, `declined` — not uppercase |
