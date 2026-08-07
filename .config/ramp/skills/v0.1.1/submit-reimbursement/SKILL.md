---
name: ramp-submit-reimbursement
area: Reimbursements
supported_surfaces: [cli, mcp]
description: |-
  Submit an out-of-pocket reimbursement from a receipt. Use when: 'submit reimbursement',
  'reimburse me', 'I paid out of pocket', 'expense a receipt', 'file reimbursement',
  'OOP expense', 'I bought something for work'. Do NOT use for: approving reimbursements
  (use ramp-approval-dashboard), uploading receipts to card transactions (use ramp-receipt-compliance),
  or editing existing reimbursements.
---

## Non-Negotiables

- **Pass `--rationale` on every command** — it is a required field on these agent-tools (a non-empty string, max 1024 chars). With `--json`, supply it as a `"rationale"` key in the body. Omitting it returns `HTTP 422 (DEVELOPER_INVALID_SCHEMA)`, in both agent and human modes.
- Never submit without confirming the details with the user first. Show amount, merchant, memo, fund, and accounting categories before submitting.
- Receipts must be **base64-encoded** for upload. Accepted types: PNG, JPEG, PDF, HEIC, WEBP.
- All CLI flags use **underscores**, not hyphens (e.g., `--fund_uuid`, `--page_size`).
- Reimbursement amounts are in **dollars** (not cents).
- After editing, always check `missing_items` in the response. Do not submit until all required items are resolved.

## Workflow

### Step 1: Upload the receipt

The user must provide a receipt file. Base64-encode and upload it:

```bash
# Encode the file
base64 -i /path/to/receipt.pdf | tr -d '\n'

# Upload (no --transaction_uuid — this is for a new reimbursement, not a card transaction)
ramp receipts upload \
  --content_type "application/pdf" \
  --filename "receipt.pdf" \
  --file_content_base64 "{base64_string}" --rationale "Upload the receipt"
```

Response returns `receipt_uuid`. Save it for the next step.

### Step 2: Create a draft reimbursement from the receipt

```bash
ramp reimbursements create {receipt_uuid} --rationale "Create the reimbursement from the receipt"
```

Response returns:
- `reimbursement_uuid` — the draft reimbursement ID
- `suggested_memos` — AI-generated memo suggestions based on the receipt
- `suggested_codings` — suggested accounting category selections
- `suggested_funds` — suggested spend allocations to charge
- `missing_items` — what still needs to be filled in before submission
- `reimbursement_link` — direct link to view in the Ramp app

### Step 3: Fill in required fields

Check `missing_items` from the create response. Common required fields:

| Missing item | How to fill |
|---|---|
| `missing_memo: true` | Edit with `--memo` |
| `missing_fund: true` | Edit with `--fund_uuid` (pick from `suggested_funds` or list funds) |
| `missing_tracking_categories` (non-empty) | Edit with `--json` to set category selections |
| `missing_receipt: true` | Should not happen if you created from a receipt |

Use suggestions from the create response when available:

```bash
# Set memo and fund from suggestions
ramp reimbursements edit {reimbursement_uuid} \
  --memo "Coffee with client" \
  --fund_uuid "{suggested_fund_uuid}" --rationale "Update the reimbursement for the user"
```

For tracking categories, use `--json`:

```bash
ramp reimbursements edit {reimbursement_uuid} --json '{
  "rationale": "Update the reimbursement for the user",
  "reimbursement_uuid": "{uuid}",
  "tracking_category_selections": [
    {
      "category_uuid": "{category_uuid}",
      "option_uuid": "{option_uuid}"
    }
  ]
}'
```

If no suggestions are available for the fund, list the user's funds:

```bash
ramp funds list --agent --rationale "List the user's funds"
```

**After each edit**, check the response's `missing_items`. Repeat until all required items are resolved (all `false` / empty).

### Step 4: Confirm with the user

Present the complete reimbursement before submitting:

```
Ready to submit:
  Amount:    $42.50
  Merchant:  Blue Bottle Coffee
  Memo:      Coffee with client — discussed Q2 roadmap
  Fund:      Social bonding & Team outings 2026
  Category:  70103 - Company Meals
  Receipt:   attached

Submit for approval?
```

### Step 5: Submit

```bash
ramp reimbursements submit {reimbursement_uuid} --rationale "Submit the reimbursement"
```

Response returns `reimbursement_uuid` and `error_message` (null on success).

After submitting, tell the user:
- The reimbursement has been submitted for approval
- Link to view it: the `reimbursement_link` from the create/edit response
- They'll be notified when it's approved

## Editing After Rejection

If a reimbursement was rejected and the user wants to fix and resubmit:

```bash
# Revert to draft
ramp reimbursements resubmit {reimbursement_uuid} --rationale "Resubmit the reimbursement"

# Edit as needed
ramp reimbursements edit {reimbursement_uuid} --memo "Updated memo with details" --rationale "Update the reimbursement for the user"

# Submit again
ramp reimbursements submit {reimbursement_uuid} --rationale "Submit the reimbursement"
```

## Duplicating a Previous Reimbursement

`ramp reimbursements duplicate` exists, but it is not a complete CLI path for a new receipt-backed reimbursement.
The duplicate keeps the prior coding context, but it does **not** copy the receipt, and the CLI cannot attach a new receipt to that duplicated draft afterward.

If the user needs to submit a new reimbursement with a new receipt, the executable CLI path is:

```bash
# Find a previous reimbursement to reference
ramp reimbursements list --reimbursements_to_retrieve my_reimbursements --page_size 10 --rationale "List the user's reimbursements"

# Duplicate exists, but the draft will still be missing a receipt
ramp reimbursements duplicate {previous_reimbursement_uuid} --rationale "Duplicate the reimbursement"

# Upload the new receipt
ramp receipts upload --content_type "image/jpeg" --filename "gym-apr.jpg" \
  --file_content_base64 "{base64}" --rationale "Upload the receipt"

# Create a fresh reimbursement from that receipt
ramp reimbursements create {receipt_uuid} --rationale "Create the reimbursement from the receipt"

# Re-apply memo, fund, and tracking categories, then submit
ramp reimbursements edit {reimbursement_uuid} --memo "Monthly gym membership" --rationale "Update the reimbursement for the user"
ramp reimbursements submit {reimbursement_uuid} --rationale "Submit the reimbursement"
```

Do not imply that a new receipt can be attached to the duplicated reimbursement via CLI. `receipts attach` is for card transactions only, and `submit` can fail with "receipt must be specified" if the duplicate has no receipt.

## Example Session

```
User: I bought coffee for a meeting yesterday, here's the receipt ~/Downloads/bluebottle.jpg

Agent: Let me upload that receipt and create a reimbursement.
> base64 -i ~/Downloads/bluebottle.jpg | tr -d '\n'
> ramp receipts upload --content_type "image/jpeg" --filename "bluebottle.jpg" \
>   --file_content_base64 "{base64}" --rationale "Upload the receipt"

Receipt uploaded (receipt_uuid: `<receipt_id>`).

> ramp reimbursements create <receipt_id> --rationale "Create the reimbursement from the receipt"

Draft created. The receipt shows Blue Bottle Coffee, $12.50.
Suggested memos: "Coffee at Blue Bottle for team meeting"
Suggested fund: "Social bonding & Team outings 2026"
Missing: memo, fund, Category (GL account)

Let me fill in the details using the suggestions:
> ramp reimbursements edit <reimbursement_id> \
>   --memo "Coffee at Blue Bottle for team meeting" \
>   --fund_uuid "<fund_id>" --rationale "Update the reimbursement for the user"

All required items resolved. Ready to submit:
  Amount:    $12.50
  Merchant:  Blue Bottle Coffee
  Memo:      Coffee at Blue Bottle for team meeting
  Fund:      Social bonding & Team outings 2026
  Category:  70103 - Company Meals
  Receipt:   attached

Submit for approval?

User: yes

Agent: > ramp reimbursements submit <reimbursement_id> --rationale "User confirmed submitting the $12.50 Blue Bottle reimbursement for approval"
Submitted! Your reimbursement is now pending approval.
View it using the `reimbursement_link` returned by Ramp.
```

## When NOT to Use

- **Approving reimbursements** — use ramp-approval-dashboard
- **Uploading receipts to card transactions** — use ramp-receipt-compliance
- **Editing memos or categories on card transactions** — use ramp-transaction-cleanup
- **Canceling an approved reimbursement** — tell the user to contact their manager or use the Ramp app

## Gotchas

| Issue | Fix |
|---|---|
| `create` requires a `receipt_uuid` | Always upload the receipt first, then create |
| `duplicate` does not copy receipts | Upload a new receipt separately, or use `create` from a receipt instead |
| `receipts attach` is for card transactions only | For reimbursements, use `create {receipt_uuid}` to attach at creation time |
| Submit fails with "receipt must be specified" | The reimbursement was created without a receipt (e.g., via `duplicate`). Create a new one from a receipt instead. |
| `missing_tracking_categories` has entries | Use `--json` with `tracking_category_selections` to set them. Each entry in the missing list shows the `category_uuid` and `category_name` needed. |
| `suggested_funds` may be empty | Fall back to `ramp funds list` to find available funds |
| Large receipt files hit shell arg limits | For files >100KB, write base64 to a temp file and read it into the `--file_content_base64` flag |
| Amount not editable via CLI | The amount comes from the receipt. If wrong, the user should create a new reimbursement with the correct receipt. |
