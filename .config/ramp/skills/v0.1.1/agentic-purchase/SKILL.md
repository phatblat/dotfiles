---
name: ramp-agentic-purchase
area: Agentic Commerce
supported_surfaces: [browser, cli, mcp]
description: "Make purchases using Ramp agent cards via browser checkout, then complete all transaction requirements (memo, tracking categories, receipt, trip). Use when asked to buy something with an agent card, make a payment using Ramp, spend from a fund, complete missing transaction items, or test the agent card payment flow. Also use when asked about agent card access, availability, or how to get started with Agentic Cards. Requires ramp CLI and ramp-browser-automation skill."
---

# Agentic Purchase

End-to-end agent card purchasing: pick a fund, get a payment token via `ramp` CLI, pay via browser, then fill all missing transaction items.

## Access & Enrollment

Agent Cards are available via self-serve enrollment. **Enrollment is a mutation** — it enrolls the authenticated user's business in Agent Cards, enabling agent card funds and fund access. An availability, setup, or eligibility question is **not** consent to enroll: first answer the question, tell the user that enrolling activates Agent Cards for their business, and ask for explicit confirmation. Only after the user confirms, enroll using the CLI:

```bash
ramp funds enroll --agent --rationale "User confirmed enrolling the business in Agent Cards"
```

The user must be authenticated (`ramp auth login`) and have appropriate permissions on their Ramp business. Once enrollment succeeds, the user can immediately use `funds list` and `funds creds` to access their agent card funds.

For more information, visit **https://agents.ramp.com/cards**.

Use this guidance for:

- "What are Agentic Cards?" or "How do I get agent cards?"
- Access, availability, enrollment, or setup questions
- Users who hit eligibility errors when running `funds list` or `funds creds`

In every case, describe what enrollment does and get an explicit "yes" before running `funds enroll`.

If the user is already enrolled, proceed with the workflow below.

## Prerequisites

- `ramp` CLI installed and authenticated (`ramp auth login`)
- `ramp-browser-automation` skill available for browser checkout
- Business enrolled in Agent Cards (see [Access & Enrollment](#access--enrollment) to enroll if not)

## CLI conventions

- Pass `--agent` for machine-readable JSON output (documented shape is top-level, immediately after `ramp`: `ramp --agent funds list`)
- Use positional arguments where supported (e.g., `ramp --agent funds creds <fund_uuid>`, `ramp --agent transactions missing <transaction_uuid>`)
- Use `--json` for complex payloads (e.g., `ramp --agent transactions edit`)
- Every subcommand accepts `--json`, `--dry_run` (`-n`), and `--help`
- **`--rationale` is required on every subcommand** — a non-empty string (max 1024 chars) explaining why you are making the call. With `--json`, put it in the body as a `"rationale"` key instead. Omitting it returns `HTTP 422 (DEVELOPER_INVALID_SCHEMA)`, even in `--agent` mode.

## Hard rules

- **Two distinct amount thresholds — respect both:**
  - **User preauth tolerance:** policy-level, ~10% over requested. Stop and re-ask if exceeded.
  - **Visa cryptogram auth cap:** the cryptogram from `ramp --agent funds creds ... --amount X` rejects any charge > X at the network level — even $0.01 over declines. If the merchant's final total exceeds the cryptogram amount (bag fees, surprise tax, currency conversion), the old cryptogram is unusable — burn it, pull fresh creds at the corrected amount, and re-preauth if the new amount exceeds the user's original 10% tolerance.
- **Run the browser headed, never `--headless`.** Purchase flows need the user able to see and intervene — bot checks, 3DS, and login walls all require human input. See `ramp-browser-automation` for the headed-default rule.
- **Stop if anything unexpected happens.** 3DS challenge, login wall, CAPTCHA, bot-block page, merchant form you can't parse → screenshot, hand off to the user via the visible Chrome window per the human-handoff pattern in `ramp-browser-automation`, and wait. Do not retry blindly.

## Phase 1: Payment

### Step 1 — Pick a fund

```bash
ramp funds list --agent --rationale "List the user's funds"
```

First select for purpose fit, then technical eligibility:

- Match the merchant and purchase purpose to the fund's intended use before considering balance or access.
- Treat broad, admin, or shared-access funds as a hazard: technical access is not approval, and the purpose-fit bar is higher when many funds are visible.
- If no appropriate fund exists, stop and ask the user which fund to use or whether to proceed through the standard card request/approval flow. Do not keep trying broad/admin funds automatically.

Then verify the selected fund has:

- `available_balance` covers the purchase amount
- `currency` matches the merchant
- `allowed_merchants` / `allowed_categories` permit the purchase (empty = unrestricted)

**Guest-checkout PII:** If no signed-in merchant account (header shows "Sign in"), guest checkout needs full name, email, phone, and shipping/billing address. Do NOT proxy these from `cardholder_name` / `billing_address` on the creds — those are for the payment form only, not the merchant's contact fields. Ask the user explicitly.

**Cart-state pre-flight:** Before generating creds for a merchant with a persistent cart (Walmart, Amazon, CVS, etc.), navigate to the cart and confirm it contains only the intended item at the expected price. Pre-existing items cookie-persist and will be charged alongside yours. If stale items exist, remove them (or ask the user to) before generating creds.

### Step 2 — Get payment token

Run `funds creds` only after the user confirms the selected fund, merchant/amount, and rationale.

```bash
ramp --agent funds creds "<fund_uuid>" \
  --amount "45.00" \
  --currency_code "USD" \
  --merchant_name "Children's Hunger Fund" \
  --merchant_url "https://childrenshungerfund.org" \
  --merchant_country_code "US" \
  --rationale "User approved \$45 donation to Children's Hunger Fund"
```

Returns `pan`, `cvv`, `expiration_month`, `expiration_year`.

**Zsh `$` escape trap:** Zsh double-quoted `"Purchase $5 credits"` expands `$5` to the 5th positional (empty), so the rationale silently loses the amount. Escape as `\$5` or use single quotes when passing dollar amounts in `--rationale` or other flags.

**Key behaviors:**

- Each call returns a **fresh CVV** — get creds immediately before checkout
- Tokens are **single-use**
- Funds are **reusable** across multiple calls

### Step 3 — Pay via browser

Load the `ramp-browser-automation` skill, then:

1. Open merchant site:
   ```bash
   cd ~/.pw-agent && ./pw open "https://merchant.com/donate"
   ```
2. Navigate to checkout / donation page
3. Take a snapshot to find form fields:
   ```bash
   ./pw snapshot
   SNAPSHOT=$(ls -t .playwright-cli/*.yml | head -1)
   grep -iE "card|number|name|expir|cvv|cvc|amount|donate" "$SNAPSHOT" | head -20
   ```
4. Fill payment form:
   ```bash
   ./pw fill <card_number_ref> "<pan>"
   ./pw fill <name_ref> "<cardholder_name>"
   ./pw fill <expiry_ref> "<MM/YY>"
   ./pw fill <cvv_ref> "<cvv>"
   ```
5. If the merchant has saved cards, click "Add a new card" first
6. Submit the payment:
   ```bash
   ./pw click <submit_ref>
   ```
7. Take a screenshot to confirm success:
   ```bash
   ./pw screenshot
   ```

**Tip:** If the donation/checkout page has an amount field, fill it before the card details. Some sites validate amount first.

**Synthetic-fill detection:** Stripe Elements and similar modern tokenizers silently reject synthetic property-setter fills — the submit button stays enabled, no error surfaces, nothing submits, no network request fires. If `./pw fill` dispatches real keystroke events this is fine; if it only sets `.value`, the submit will stall for PAN/CVV/expiry fields specifically. Workaround: use coordinate-click to focus plus compositor-level keystroke events (`Input.insertText` at CDP) for card fields. Billing-address fields are not guarded the same way.

**Card-swap close-and-reopen rule:** After pulling fresh creds mid-flow (e.g., retry at a higher amount), close the merchant's payment form entirely and re-open before filling. The processor's validator can retain stale state from the prior card and refuse to tokenize the new one (observed on Stripe, 2026-04-21). Do not overwrite PAN/CVV in place.

#### Merchant form quirks — expiration date

- **Stripe Elements:** single combined field, format `MM / YY`, auto-inserts the ` / `.
- **Vantiv eProtect** (e.g., CVS): separate Month/Year `<select>` elements, values are 2-digit (`"29"` for 2029). Passing `"2029"` silently fails — the dropdown stays empty, with "Select a year / Expiration date invalid" only showing after submit.
- Always check whether the year field expects `YY` or `YYYY` before filling.

## Phase 2: Complete transaction

Digital merchants (donations, SaaS) post transactions **within seconds**. Physical merchants may take minutes to hours.

### Step 4 — Find the transaction

```bash
ramp transactions list --agent \
  --transactions_to_retrieve my_transactions \
  --page_size 5 \
  --details_to_include_in_response submitted_items --rationale "List the user's transactions"
```

Match by amount + merchant name to find the transaction `id`.

### Step 5 — Check missing items

```bash
ramp transactions missing --agent "<transaction_id>" --rationale "Check missing items on the transaction"
```

### Step 6 — Fill missing items

#### Memo

Use AI suggestions when available:

```bash
ramp transactions memo-suggestions --agent "<transaction_id>" --rationale "Fetch AI-suggested memos"
```

Then set the memo:

```bash
ramp transactions edit --agent "<transaction_id>" \
  --memo "Donation to Children's Hunger Fund" \
  --user_submitted_fields memo --rationale "Update the transaction for the user"
```

#### Tracking categories

First, list required categories:

```bash
ramp accounting categories --agent --transaction_uuid "<transaction_id>" --rationale "List tracking categories"
```

Then look up options for each category:

```bash
ramp accounting category-options --agent "<category_uuid>" \
  --transaction_uuid "<transaction_id>" \
  --query_string "search term" \
  --page_size 10 --rationale "List options for the tracking category"
```

Set categories via `--json` for batch updates:

```bash
ramp transactions edit --agent --json '{
  "rationale": "Update the transaction for the user",
  "transaction_uuid": "<transaction_id>",
  "tracking_category_selections": [
    {"category_uuid": "<cat_id>", "option_selection": "<option_uuid>"}
  ],
  "user_submitted_fields": ["tracking_category_selections"]
}'
```

**When you don't know what to fill:** Do not guess. Look up available options, present 3-5 best matches to the user, and ask them to pick.

#### Trip

For travel-related transactions:

```bash
ramp transactions trips --agent --rationale "List trips to assign to the transaction"
```

Then assign:

```bash
ramp transactions edit --agent --json '{
  "rationale": "Update the transaction for the user",
  "transaction_uuid": "<transaction_id>",
  "trip_selection": {"trip_uuid": "<trip_uuid>"},
  "user_submitted_fields": ["trip_selection"]
}'
```

Not travel-related:

```bash
ramp transactions edit --agent --json '{
  "rationale": "Update the transaction for the user",
  "transaction_uuid": "<transaction_id>",
  "trip_selection": {"mark_not_part_of_trip": true},
  "user_submitted_fields": ["trip_selection"]
}'
```

#### Receipt

**Upload a receipt from file (e.g., screenshot of confirmation page):**

```bash
ramp receipts upload --agent \
  --filename "receipt.png" \
  --content_type "image/png" \
  --file_content_base64 "$(base64 < /path/to/receipt.png)" \
  --transaction_uuid "<transaction_id>" --rationale "Upload the receipt"
```

**Attach an existing receipt:**

```bash
ramp receipts attach --agent "<receipt_uuid>" "<transaction_id>" --rationale "Attach the receipt to the transaction"
```

**No receipt — provide reason:**

```bash
ramp transactions explain-missing --agent "<transaction_id>" \
  --reason "Online donation — no receipt issued" --rationale "Record why the receipt is missing"
```

**No receipt — flag as missing:**

```bash
ramp transactions flag-missing --agent "<transaction_id>" --rationale "Generate a missing-receipt affidavit link"
```

**Pro tip:** After a successful browser checkout, take a screenshot of the confirmation page, save it, and upload it as the receipt. This covers the receipt requirement automatically.

### Step 7 — Verify completion

```bash
ramp transactions missing --agent "<transaction_id>" --rationale "Check missing items on the transaction"
```

Confirm all items resolved: `missing_receipt: false`, `missing_memo: false`, `missing_accounting_items: []`.

## Error handling

| Error                                | Action                                                                       |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| No agent card access                 | Enroll the business via `ramp funds enroll --agent`, then retry |
| Fund not eligible / no eligible card | Re-run purpose-first selection; if no appropriate eligible fund exists, ask the user instead of trying broad/admin funds automatically |
| Insufficient balance                 | Pick a fund with more balance                                                |
| Credential retrieval failed          | Retry once, then try a different fund                                        |
| 401 / token expired                  | Re-authenticate for the active env: `ramp --env <env> auth login` (auth state is stored per environment) |
| Transaction not found after payment  | Wait 30s and retry `transactions list` — some merchants have delayed posting |
| Card form submitted but nothing happens (button enabled, no error, no processing, no spinner) after 15s | Suspected silent tokenizer rejection of synthetic property-setter fills. Close form, re-open, re-fill via real keystrokes. |
| Final charge amount exceeds cryptogram auth | Cryptogram caps at `--amount`. Burn current creds, pull fresh at new amount. Re-preauth if > 10% over original. |
| Pre-existing items in cart from prior session | Remove them (or ask the user to) before generating creds. |
| 3DS challenge                        | Stop. Screenshot, then tell the user to complete 3DS in the visible Chrome window and reply when done. Resume Phase 2 once the card clears. See human-handoff in `ramp-browser-automation`. |
| CAPTCHA / reCAPTCHA / bot-check page | Stop. If the browser is headless, `./pw stop` and re-open headed first — the user cannot interact otherwise. Then screenshot and hand off per human-handoff in `ramp-browser-automation`. Do not attempt a programmatic solve. |
| Merchant shows "declined"            | A BIN decline at one processor (e.g., Vantiv eProtect at CVS) does NOT predict decline at another (e.g., Stripe at Anthropic) — each has its own risk engine. Report the merchant AND the processor (identifiable from the payment iframe's `src` if possible) so we track the BIN-vs-processor matrix. Do not retry at the same merchant. |

### Tips

- Each `funds creds` call generates a fresh CVV. If you need to retry a checkout, call `creds` again first.
- Prefer merchants with single-page checkout forms over multi-step embedded widgets.
- Some merchants have minimum transaction amounts — check before attempting small purchases.

## Workflow summary

```
funds list → pick fund
  → funds creds → get PAN/CVV
    → browser: open merchant → fill payment → submit
      → transactions list → find txn
        → transactions missing → check gaps
          → transactions edit (memo, categories, trip)
          → receipts upload (confirmation screenshot)
            → transactions missing → verify clean
```
