---
name: ramp-submit-procurement-request
area: Procurement
supported_surfaces: [cli, mcp]
description: |-
  Create, complete, and submit new, existing draft, or approved-PO change-request
  Ramp procurement requests. Use when: 'submit a procurement request', 'start a
  purchase request', 'continue my draft', 'request to buy', 'create a PO
  request', 'change an approved PO', or 'submit a software purchase'. Do NOT use
  to track or approve a submitted request (use ramp-manage-procurement), or for
  reimbursements, bills, card expenses, vendor onboarding documents, or
  contract changes not tied to an approved Ramp PO.
---

# Submit Procurement Request

Guide the user conversationally through the pre-submission request lifecycle.
Use `ramp procurement_requests` for the draft itself. Resolve CLI flags, field
IDs, and object IDs without asking the user to understand them.

## Rules

- Run commands with `--agent` and pass `--rationale` every time. With `--json`,
  put `rationale` in the JSON body. Omitting it can return
  `HTTP 422 (DEVELOPER_INVALID_SCHEMA)`.
- CLI flags use snake_case, such as `--spend_request_uuid` and `--page_size`.
- After every `draft` or `get` call, replace prior form state with the returned
  top-level `draft_state` and, for change requests, `change_request_state`;
  conditional questions may change.
- Treat `draft_state.fields` as the current visibility-based write allowlist for
  `answers` and `clear_field_ids`. Never target a field absent from `fields`.
- Treat `change_request_state.fields` as a separate write allowlist for
  `change_request_answers` and `clear_change_request_field_ids`. Never put a
  change-request form answer in `answers`, or a normal draft answer in
  `change_request_answers`.
- Treat `fields_to_answer` as the prioritized subset of visible fields that are
  missing required values or have field-level validation errors. Optional and
  already-answered visible fields may still be intentionally updated.
- Build each answer from the visible field's `answer_template`;
  `{field_id, value}` alone is not a valid generic shape.
- Never invent spend intent UUIDs, field IDs, choices, lookup IDs, or file
  UUIDs.
- Ask the user for visible-field values that cannot be resolved from their
  prompt, provided files, or a lookup. Clearly label optional questions and
  say they may be skipped; batch related questions when practical.
- Submit only when every returned form state is `ready_to_submit`, the user has
  seen the current summary and any `change_request_diff`, and they explicitly
  confirm submission.

## Workflow

```text
choose spend intent or approved PO -> confirm with user -> create/resume draft -> fill current fields
-> attach relevant files -> revalidate -> review with user -> confirm -> submit
```

## Create or Resume a Draft

For a new request, list spend intents first:

```bash
ramp procurement_requests spend-intents --page_size 50 --rationale "List procurement spend programs before drafting" --agent
```

Choose only from returned spend intent UUIDs. Match the returned name,
description, status, and outcome type to the user's request. If more than one
program fits materially, ask the user to choose.

**Creating a draft is a write** — it creates a persistent procurement draft
under the selected program. Before running it, show the user the program you
selected (name and description) and confirm they want a draft created there;
selecting a spend intent is not itself consent to create one. Then:

```bash
ramp procurement_requests draft --spend_intent_uuid "<spend_intent_uuid>" --rationale "User confirmed drafting a procurement request under the selected spend program" --agent
```

For an existing draft, fetch its current state before editing:

```bash
ramp procurement_requests get "<spend_request_uuid>" --rationale "Fetch the current procurement draft" --agent
```

Do not reuse field IDs or visibility from an earlier response or conversation.

For a change request, first use `ramp requests search` and `ramp requests get` to
identify and review the original approved purchase-order request. Use its
`spend_request_uuid` as `existing_spend_request_uuid`; do not use the unified
`unified_request_id` or `purchase_order_id` in its place. Confirm with the user
which approved purchase order the change request should be drafted from — same
confirm-before-draft rule as above — then create the linked child with

```bash
ramp procurement_requests draft --existing_spend_request_uuid "<original_spend_request_uuid>" --rationale "Create a change-request draft from the approved purchase order" --agent
```

`existing_spend_request_uuid` and `spend_intent_uuid` are mutually exclusive.
After creation, continue the returned child by passing only its
`spend_request_uuid`; do not resend `existing_spend_request_uuid`.

## Fill and Revalidate the Draft

Read the top-level `draft` summary plus `draft_state.status`,
`draft_state.fields`, `draft_state.fields_to_answer`, and
`draft_state.validation_errors`. Start with the IDs in `fields_to_answer`: they
are the visible fields that are missing required values or have field-level
validation errors. The broader `fields` list is the write boundary. Optional or
already-answered fields absent from `fields_to_answer` may be updated when the
user intends to change them or their value is supported by the user's request.

For a change request, inspect `change_request_state.status`, fields,
`fields_to_answer`, and validation errors independently. Build normal form
answers from `draft_state.fields` and send them in `answers`. Build change-request
form answers from `change_request_state.fields` and send them in
`change_request_answers`.

For the current visible fields, prioritizing `fields_to_answer`:

| Situation | Action |
|---|---|
| Required and known | Fill it |
| Required and unknown | Ask the user |
| Optional and supported by user information, a file, or a lookup | Fill it |
| Optional but unknown or weakly implied | Ask; label it optional and offer to skip it |
| Ambiguous and material | Ask one concise question |

Batch known standard fields and form answers into as few updates as practical:

```bash
ramp procurement_requests draft --json '{
  "spend_request_uuid": "<spend_request_uuid>",
  "rationale": "Populate current procurement request fields",
  "request_name": "<request title>",
  "currency": "USD",
  "line_items": [
    {"description": "<item>", "amount": "1000.00"}
  ],
  "answers": [
    {"answer_type": "text", "field_id": "<field_id>", "value": "<answer>"}
  ]
}' --agent
```

Update semantics:

- Omit `line_items` to preserve them. Send the complete desired list to replace
  them, or `[]` to clear them. `line_items: null` is invalid.
- For a change request, begin with the complete returned line-item list, preserve
  every item UUID and all unchanged properties, modify only the user-requested
  values, and send that full list. `line_items` is full replacement, not a
  patch; sending only a changed item deletes omitted items.
- A matching line-item UUID preserves existing tracking categories, custom
  fields, withholding rates, and external IDs that are not editable input. Do
  not remove and recreate a line merely to change its amount.
- Omit `currency` to preserve it. `currency: null` is invalid.
- Use `clear_field_ids` to clear current visible custom-form answers; do not
  send null answer values.
- Use `clear_change_request_field_ids` only for visible change-request fields;
  do not send null `change_request_answers`.

After every update, replace your prior field state with the returned
`draft_state`:

- `needs_input`: resolve `fields_to_answer`, then fill supported optional visible
  fields when useful.
- `has_validation_errors`: fix the returned validation errors.
- New or removed fields: rebuild the visible write set from `fields`, then
  prioritize the new `fields_to_answer` subset.
- `ready_to_submit`: stop editing and review the request with the user.

Apply the same transition rules independently to a non-null
`change_request_state`. After each change-request update, inspect
`draft.original_request` and `draft.change_request_diff`. `original_request` is the
approved purchase-order request being changed and must match the user's intended
PO. The diff must show only the intended old and new values. Stop on an empty or
unexpected diff instead of submitting.

`LINE_ITEM` entries in `change_request_diff` are sparse and include only changed
values. Overlay a present `new_value` on `old_value`: a
null property means unchanged, while the whole `new_value` is null when the line
was removed. Do not report omitted or null properties as changes.

A visible form field may ask whether the purchase is new or a renewal; answer it
when known. Do not use this workflow to amend or renew a contract outside a
currently visible draft field.

## Resolve Lookup Fields

Run a lookup only when a current visible field requires an existing Ramp object
ID. Prefer that field's `lookup` metadata and `answer_template` over these
examples:

```bash
# Vendor
ramp vendors search --search_term "<vendor name>" --limit 10 --rationale "Find the vendor UUID for the procurement request" --agent

# Department
ramp business departments --name_filter "<department name>" --rationale "Find the department UUID for the procurement request" --agent

# Merchant
ramp merchant search --query "<merchant name>" --limit 10 --rationale "Find the merchant ID for the procurement request" --agent

# Merchant category
ramp merchant categories --rationale "List merchant category IDs for the procurement request" --agent
```

Use IDs returned by the lookup; never derive them from display labels.

Custom-form answers are typed objects. Copy the visible field's
`answer_template` and replace its placeholders. Representative shapes:

```json
{"answer_type":"text","field_id":"<field_id>","value":"Business justification"}
{"answer_type":"vendor","field_id":"<field_id>","payee_uuid":"<vendor_uuid>"}
{"answer_type":"merchant_category","field_id":"<field_id>","category_ids":[456]}
{"answer_type":"file_upload","field_id":"<field_id>","file_uuids":["<file_uuid>"]}
```

For text-like fields such as `paragraph`, `email`, `link`, and `date`, preserve
the field's exact `answer_type`. For complex fields such as `address` and
`contact`, fill the exact properties returned in `answer_template`.

## Attach Files

If the user provides a file, first inspect the current visible fields. Upload it
only when a visible file field's label or help text matches the file's purpose,
such as a contract, quote, invoice, or supporting document. An already-answered
visible file field may accept an intentional additional or replacement file.

```bash
ramp procurement_requests upload-file "<file_field_id>" "<spend_request_uuid>" --file "/absolute/path/to/file.pdf" --rationale "Upload the document requested by the procurement form" --agent
```

Before uploading, retain whether the selected `field_id` came from
`draft_state.fields` or `change_request_state.fields`. Field IDs identify their
form context. Use the returned `answer` object without rebuilding it, and place
it back into the same form collection:

| Selected field collection | Draft update property |
|---|---|
| `draft_state.fields` | `answers` |
| `change_request_state.fields` | `change_request_answers` |

For a request-form upload:

```bash
ramp procurement_requests draft --json '{
  "spend_request_uuid": "<spend_request_uuid>",
  "rationale": "Attach the uploaded document to its procurement form field",
  "answers": [
    <returned answer object>
  ]
}' --agent
```

For a change-request-form upload:

```bash
ramp procurement_requests draft --json '{
  "spend_request_uuid": "<spend_request_uuid>",
  "rationale": "Attach the uploaded document to its change-request form field",
  "change_request_answers": [
    <returned answer object>
  ]
}' --agent
```

Do not upload a file when no current visible file field matches it, and do not
attach it to an unrelated field merely because that field is visible.

## Review and Submit

When the status is `ready_to_submit`, summarize the current `draft`, answered
form fields, and attached files in user language:

```text
I drafted this procurement request:

Spend program: Software
Request: Figma annual subscription
Vendor: Figma
Amount: USD 90,000.00
Line items:
- Figma Enterprise, 100 seats: USD 90,000.00
Filled form details:
- Business justification: Design collaboration
Attached files:
- figma-agreement.pdf

Should I submit it?
```

A confirmation given before the user sees this current summary does not count.
For a change request, also show the approved PO request from `original_request`
and every old/new value in `change_request_diff`. Ask the user to explicitly confirm
that exact diff. Submit only after they confirm the summarized request:

```bash
ramp procurement_requests submit "<spend_request_uuid>" --confirmed --rationale "Submit the confirmed procurement request" --agent
```

Report the returned spend request UUID, status, and submission time. Include a
web path only when the response returns one.

## Stop and Ask

Stop instead of guessing when:

- More than one spend intent materially fits.
- A required field in `fields_to_answer` lacks a known value.
- A lookup-backed field cannot be resolved.
- The user supplied a file but no current field matches it.
- Validation errors remain after correcting the supplied values.
- `original_request` does not match the intended original approved request.
- A change-request diff is empty, incomplete, or contains an unintended change.

For `HTTP 422`, first verify that `rationale` is present and the request matches
the current field templates.
