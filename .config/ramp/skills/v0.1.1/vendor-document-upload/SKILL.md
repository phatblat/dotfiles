---
name: ramp-vendor-document-upload
area: Vendor Management
supported_surfaces: [cli, mcp]
description: |-
  Upload vendor documents such as W-9/W-8 tax forms, contracts, COIs,
  payment instructions, and onboarding paperwork, then check bulk upload
  OCR and matching status. Use when: 'upload a W9', 'attach a vendor
  contract', 'bulk upload supplier docs', 'check vendor document status',
  'upload a COI for a vendor'. Do NOT use for card transaction receipts
  (use ramp-receipt-compliance) or bill invoice attachments (use bills commands).
---

## Non-Negotiables

- **Pass `--rationale` on every command** — it is a required field on these agent-tools (a non-empty string, max 1024 chars). With `--json`, supply it as a `"rationale"` key in the body. Omitting it returns `HTTP 422 (DEVELOPER_INVALID_SCHEMA)`, in both agent and human modes.
- Never attach a document to a `vendor_uuid` unless the user has confirmed the vendor and document category.
- If the vendor identity is uncertain, omit `--vendor_uuid` and let Ramp's matching/triage flow handle it.
- Always run `-n/--dry_run` before uploading when using a known `vendor_uuid`.
- Vendor document file contents must be base64-encoded.
- CLI request flags use snake_case, for example `--document_category` and `--file_content_base64`.
- Prefer `--agent` when checking bulk status so counts and per-document fields are easy to parse reliably.

## Workflow

### Mode 1: Attach one document to a known vendor

Use this when the user gives both a file path and the target vendor UUID.

```bash
# Base64 encode the file
base64 -i /path/to/acme-w9.pdf | tr -d '\n'

# Dry run first
ramp vendors attach-document \
  --vendor_uuid "vnd_123" \
  --filename "acme-w9.pdf" \
  --content_type "application/pdf" \
  --file_content_base64 "{base64_string}" \
  --document_category W9 \
  --dry_run --rationale "Upload the vendor document"

# If the request body is correct, upload for real
ramp vendors attach-document \
  --vendor_uuid "vnd_123" \
  --filename "acme-w9.pdf" \
  --content_type "application/pdf" \
  --file_content_base64 "{base64_string}" \
  --document_category W9 --rationale "Upload the vendor document"
```

The upload response includes:

- `document_uuid`
- `vendor_uuid`
- `document_category`
- `original_filename`
- `document_url` (temporary download URL, when available)

### Mode 2: Upload one document into vendor matching/triage

Use this when the user has a file but not a trustworthy vendor UUID yet.

```bash
ramp vendors attach-document \
  --filename "acme-contract.pdf" \
  --content_type "application/pdf" \
  --file_content_base64 "{base64_string}" \
  --document_category VENDOR_CONTRACT --rationale "Upload the vendor document"
```

If `vendor_uuid` is omitted in the response, tell the user the document was uploaded into the matching flow and may need review in Ramp.

### Mode 3: Bulk upload many vendor documents

`documents` is a complex array, so use `--json` for the request body.

```bash
ramp vendors bulk-upload \
  --dry_run \
  --json '{
    "rationale": "Bulk upload vendor documents",
    "documents": [
      {
        "filename": "acme-w9.pdf",
        "content_type": "application/pdf",
        "file_content_base64": "{base64_w9}"
      },
      {
        "filename": "acme-coi.pdf",
        "content_type": "application/pdf",
        "file_content_base64": "{base64_coi}"
      }
    ],
    "vendor_uuid": "vnd_123"
  }'
```

If the dry run is correct, repeat without `--dry_run`. The response returns `batch_id`, `upload_job_uuid`, and `document_count`.

If the user does not have a single confirmed vendor UUID for all files, omit `vendor_uuid` so each document enters bulk triage.

### Mode 4: Check bulk upload status

Poll the batch until OCR/matching has finished or attention is needed:

```bash
ramp --agent vendors bulk-upload-status "batch_123" --rationale "Check OCR/matching progress for the user's document batch"
```

Useful filters:

```bash
# Only W-form documents
ramp --agent vendors bulk-upload-status "batch_123" --is_w_document --rationale "Check OCR status of W-form documents in the batch"

# Exclude W-form documents
ramp --agent vendors bulk-upload-status "batch_123" --no-is_w_document --rationale "Check OCR status of non-W-form documents in the batch"
```

Summarize these response fields for the user:

- `upload_job.status`, `upload_job.status_reason`, and `upload_job.is_terminal`
- `document_count`
- `matched_document_count`
- `unmatched_document_count`
- `documents_with_running_ocr_count`
- `documents_needing_attention_count`
- `review_required`

For each document that needs attention, include `original_filename`, `document_category`, `needs_attention`, matched vendor name/UUID if present, `vendor_match_score`, and W-form OCR details (`is_likely_w8`, `is_likely_w9`, `tax_details`) when available.

## Document Category Reference

Use the narrowest category that matches the file:

| Document type | `document_category` |
|---|---|
| W-9 form | `W9` |
| W-8 form | `W8` |
| Vendor contract | `VENDOR_CONTRACT` |
| MSA | `MSA` |
| NDA | `NDA` |
| Statement of work | `SOW` |
| Certificate of insurance | `CERTIFICATE_OF_INSURANCE` |
| Payment instructions | `PAYMENT_INSTRUCTIONS` |
| Voided check | `VOIDED_CHECK` |
| Tax paperwork that is not clearly W-8/W-9/1099 | `TAX_DOCUMENT` |
| Anything else | `OTHER` |

If the category is ambiguous, ask the user before uploading. Do not guess between legal, tax, and payment document categories.

## MIME Type Reference

| Extension | `content_type` |
|---|---|
| `.pdf` | `application/pdf` |
| `.png` | `image/png` |
| `.jpg`, `.jpeg` | `image/jpeg` |
| `.heic` | `image/heic` |
| `.webp` | `image/webp` |

## How to Present Results

For a single upload, confirm the filename, category, attachment target, and returned `document_uuid`:

```
Uploaded acme-w9.pdf as W9 and attached it to vendor vnd_123.
Document UUID: doc_456
```

For a bulk batch, lead with job progress and whether manual review is still required:

```
Batch batch_123
Status: SUCCEEDED - all documents processed
Matched: 8 / 10
Needs review: 2

Needs attention
  acme-w9.pdf     W9               Acme Corp (score 0.92)
  wire-info.pdf   PAYMENT_INSTRUCTIONS   no vendor match
```

## When NOT to Use

- Uploading receipts to transactions or reimbursements - use ramp-receipt-compliance.
- Editing transaction memo/category/fund metadata - use ramp-transaction-cleanup.
- Approving bills, transactions, requests, or reimbursements - use ramp-approval-dashboard.
- Retrieving invoice attachments from a submitted bill - use `ramp bills attachments`.

## Gotchas

| Issue | Fix |
|---|---|
| `ramp vendors bulk-upload` rejects `documents` flags | Build the request body with `--json`; `documents` is a complex array. |
| Uploading a large base64 string hits shell argument limits | Split into smaller batches or put the JSON payload in a temp file and pass it through `--json`. |
| `vendor_uuid` is unknown or uncertain | Omit it and use matching/triage mode instead of guessing. |
| Bulk status still shows running OCR jobs | Re-run `ramp --agent vendors bulk-upload-status {batch_id}` until `upload_job.is_terminal` is true. |
| `review_required` is true or documents have `needs_attention: true` | Tell the user which files need review and why, instead of claiming the batch is fully done. |
| `document_url` is present | Treat it as temporary and avoid storing it as a durable reference. |
