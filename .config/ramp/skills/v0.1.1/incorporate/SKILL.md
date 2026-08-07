---
name: ramp-incorporate
area: Getting Started
supported_surfaces: [cli]
description: |-
  Resolve the COMPLETE_INCORPORATION blocker in a Ramp financing application by
  filing a US LLC through Ramp. Use when GET /developer/v1/applications/progress
  returns user_action: COMPLETE_INCORPORATION with provider: doola.
  Also use after a submitted unformed-entity Ramp application reaches
  IN_REVIEW / WAIT_FOR_RAMP and the applicant explicitly asks to file the LLC.
  Also use for: "incorporate my business", "file an LLC for me", "set up an LLC
  through Ramp", "Ramp incorporation", "I don't have a legal entity yet".
  Do NOT use for: businesses that already have an EIN (use ramp-apply-for-account PATCH
  instead), non-US founders or country fields, companies without a US principal
  place of business, or C-Corp formation (Phase 1 is LLC-only).
---

# Incorporate With Ramp

This skill resolves the `COMPLETE_INCORPORATION` blocker in a Ramp financing
application. It runs entirely within the agent's OAuth session — no separate
third-party account is needed.

**Incorporating through Ramp has a cost.** Pricing and details are the source of
truth at https://agents.ramp.com/docs/account/incorporate. Before filing, tell
the person it isn't free and offer to fetch that page so they can see the current
price; submit the formation only after they're OK with it.

Use this as a continuation of the `ramp-apply-for-account` skill. If there is no current
Ramp application, start there first so the invite, application record, and
business-scoped OAuth session exist before any incorporation write command runs.
Once the financing application has been submitted and progress is waiting on
Ramp (often application `status` = `IN_REVIEW` with required action
`WAIT_FOR_RAMP`), proceed with the incorporation submission path; do not wait
for FA approval or underwriting to clear first. Do not start formation while the
application is only `ready_for_submission=true`. In particular, do not run
`ramp incorporation applicant create` or `ramp incorporation submit` before the
applicant has reviewed and submitted the financing application.

## When to Use

Use this skill in either of these cases:

- `GET /developer/v1/applications/progress` returned:

```json
{
  "type": "USER_ACTION_REQUIRED",
  "user_action": "COMPLETE_INCORPORATION",
  "provider": "doola",
  "reason": "NO_LEGAL_ENTITY",
  "guidance": "Run 'ramp incorporation submit' to file the LLC..."
}
```

- The person asked to "incorporate my business", "file an LLC", or "set up an
  LLC through Ramp" for the current unformed-entity Ramp application after FA
  submission, usually when progress is `IN_REVIEW` / `WAIT_FOR_RAMP`.

The applicant has `incorporation:read` and `incorporation:write` scopes in their
OAuth token.

If Ramp reports that the filing flow is unsupported, do not use this skill.
Tell the applicant that this CLI flow is unavailable for their application and
hand them the current Ramp link if progress returned one.

If the application was just created and `--wait_for_auth` was interrupted, the
returned `invite_link` still lets the applicant finish the Ramp browser handoff.
Do not run incorporation write commands until the fallback auth command or browser
callback has saved credentials for the newly-created application business.

The OAuth token must belong to the business being incorporated. If the CLI is
still authenticated to another business or a previous login, the incorporation
commands will create or read incorporation records for that other
business. Re-authenticate through the newly-created application/business before
running the write commands. **Re-authentication triggers a browser-based OAuth
flow — the user must open the Ramp email they receive and complete sign-in
before the CLI can continue.**

Use the same CLI binary, `--env`, OAuth token, and shell context for applicant
creation and formation submission. If `which ramp` resolves to an older binary,
use the explicit installed CLI path for every command in the sequence.

## SSN Handling — Critical

**Never ask the user for their full SSN or SSN last-4 in chat, and never include SSN data in any tool argument.**

The CLI does not collect SSN values for incorporation. SSN entry belongs in the
Ramp application form returned by application progress, not in
`ramp incorporation submit`, chat, CLI prompts, env vars, or `--json`.

The current formation submit path reuses owner, controller, and identity data
already collected on the Ramp financing application when it identifies at least
one owner. Do not ask for `responsible_party` or
environment variables containing SSN data and do not resend
beneficial-owner or controlling-officer payloads during formation filing. The
only exception is the explicit member fallback for a valid no-25%-owner
application described below; it sends non-sensitive `members` but still omits
`ssn_last_4`.

Before filing the LLC, complete every API-writable/non-sensitive application
field first. When the only remaining applicant-owned actions are SSN entry and
optionally phone verification, send the Ramp form link(s) so the person can
complete SSN entry directly in Ramp.

## Workflow

### 1. Confirm the blocker or direct filing path

`GET /developer/v1/applications/progress` is the source of truth for the
`COMPLETE_INCORPORATION` blocker (see `ramp-apply-for-account` skill). Query the endpoint
directly or accept the blocker context handed in by the parent agent.

If the parent agent has already surfaced a `COMPLETE_INCORPORATION` blocker
payload, capture the `reason` field. Otherwise instruct the user to check the
status page in the Ramp dashboard. Recovery branches:

- `NO_LEGAL_ENTITY` → proceed with first submission (start at Step 2).
- `NAME_CONFLICT` → all prior name options were rejected; generate new names before re-submitting.
- `STATE_COMPLIANCE` → prior state had compliance issue; consider changing state.
- `RP_IDENTITY` → responsible party identity rejected; do not re-collect or
  re-submit owner/controller/responsible-party payloads in the lean path. Re-fetch
  application progress and verify whether the FA-sourced identity fields need a
  browser correction or API-writable non-sensitive patch; if the rejection is not
  recoverable through those sources, stop and direct the user to Ramp support
  with the user-visible error message only.

If there is no active `COMPLETE_INCORPORATION` blocker but the person explicitly
asked to file an LLC for the current unformed-entity application, first re-fetch
application progress. If `ready_for_submission=true`, send the person to Ramp to
review and submit the financing application; do not start formation yet and do
not create an incorporation applicant record. If the financing application still
needs provisional incorporation preferences such as entity type, filing state,
industry, or intended filing date, return to the `ramp-apply-for-account` skill and PATCH
those application fields first. When the person is submitting now, use the
progress wait loop instead of manually polling:

```bash
ramp applications progress --env production --agent \
  --wait_for_action REVIEW_AND_SUBMIT --wait_interval 15 --wait_timeout 900
```

When the submitted application is waiting on Ramp (usually application status
`IN_REVIEW` with required action `WAIT_FOR_RAMP`) and
`needs_incorporation=true`, treat that as the direct filing path. Check
`ramp incorporation status --agent` first; proceed with first submission only
when no formation has already been submitted, and do not block on unrelated Ramp
approval or underwriting.
Do not report `WAIT_FOR_RAMP` as a stop condition until this direct filing path
has been evaluated. For submitted unformed-entity applications, the absence of
an explicit `COMPLETE_INCORPORATION` action does not mean the agent is done; it
must still check formation status and create/submit the incorporation when no
formation exists.
If `ramp incorporation status` returns a 404 saying no incorporation formation
exists, treat that as the expected first-submission state when `ramp auth status`
already confirms the current business-scoped OAuth session has
`incorporation:read` and `incorporation:write`. If auth status is missing or
ambiguous, re-authenticate before any write command.

The formation status (which this skill tracks throughout the workflow) is
available via `ramp incorporation status` once the formation is submitted.

### Country handling

This launch flow is US-only. No country lookup is required. Ramp defaults
omitted applicant, member, responsible-party, and address country fields to
`US`, and rejects non-US values for now. If you include a country or nationality
field explicitly, use `US`.

### 2. Gather formation inputs

Run these in parallel (all are read-only, no SSN involved):

```bash
ramp incorporation states --agent          # pick a state (DE is common for LLC)
ramp incorporation industries search --q "<business description>" --agent
```

Collect from the user:
- **State**: where to incorporate (default: Delaware for most businesses)
- **NAICS code**: from the industries search result
- **Business description**: 1-2 sentences (not just the name)
- **3 name options**: ranked list of LLC name preferences (Ramp files the first available)
- **Mailing address**: for official correspondence, including phone number

Do not ask the user to repeat owner, member, responsible-party, controller, or
SSN facts that are already on the Ramp application. In the normal submitted
financing-application path, Ramp uses owner/controller data from the application and the formation
payload only needs filing facts plus addresses.

Before choosing the formation payload, inspect the submitted application:

- If `controlling_officer.is_beneficial_owner` is true or
  `beneficial_owners` is non-empty, use the lean payload. Do not send `members`.
- If the controlling officer is not a beneficial owner and `beneficial_owners`
  is empty, collect and send the explicit `members` fallback in Step 6. Because
  formation starts only after financing-application submission, the application
  already includes the required no-individual-owns-25% acknowledgement. The application
  read response does not expose that acknowledgement, so do not branch on it.
- For any other empty-owner shape, return to `ramp-apply-for-account` and complete or
  correct the ownership section. Do not infer that no individual owns 25% or
  discover the fallback by repeatedly submitting the lean payload.

Do NOT collect SSN last-4 in the model context or CLI — SSN entry must happen in
the Ramp form.
For the linked financing application's provisional incorporation fields, treat
EIN as optional but do not provide it in tool calls while
`needs_incorporation=true`; Ramp backfills EIN after incorporation completes.

### 3. Create the incorporation applicant record

```bash
ramp incorporation applicant create --agent
ramp incorporation applicant get --agent
```

This is a required pre-submit gate, not an optional verification. It creates the
incorporation applicant record linked to the authenticated business and then
confirms the applicant is available to the same authenticated session that will
submit the formation. Country of residence defaults to `US`.

Run applicant create/get immediately before `ramp incorporation submit`, using
the same CLI binary, OAuth login, and shell session that will run submit.

### 4. Confirm SSN was handled in Ramp

Before `ramp incorporation submit`, re-fetch application progress. If SSN entry
is still a required applicant action, do not run the submit command yet. Tell the
user:

> To complete the LLC filing, Ramp needs your SSN last 4 to match your existing
> identity record. Your SSN last 4 is never sent through the model, CLI, command
> arguments, or env vars.
>
> **Open in Ramp:** `<deep_link_url>`
>
> Complete SSN entry in the Ramp form, then return here so I can re-fetch your
> application progress.

If phone verification is also still pending, show its link at the same time so
the person can complete both browser steps together. Resume the incorporation
submit path only after progress no longer requires SSN entry.

### 5. Authenticated-session preflight

Before the submit call, verify the public CLI session without printing
sensitive application data:

```bash
ramp auth status --env production --agent
ramp incorporation applicant create --env production --country-of-residence US --agent
ramp incorporation applicant get --env production --agent
```

Do not paste or summarize sensitive KYC output during this flow. Confirm only
that authentication and applicant retrieval succeeded; do not expose resource
identifiers or business details in diagnostics.

### 6. Submit the formation

Use the lean formation payload when the submitted Ramp application identifies
one or more owners through the controlling officer or `beneficial_owners`.
`members` and `responsible_party` are intentionally omitted; Ramp uses that
data from the submitted financing application. Do not set
SSN data in environment variables.

```bash
ramp incorporation submit --json '{
  "state": "<chosen_state>",
  "naics_code": "<naics_code>",
  "description": "<business_description>",
  "name_options": [
    {"name": "<option_1>", "entity_type_ending": "LLC"},
    {"name": "<option_2>", "entity_type_ending": "LLC"},
    {"name": "<option_3>", "entity_type_ending": "LLC"}
  ],
  "addresses": [
    {"provider": "ramp", "address_type": "registered_agent"},
    {
      "provider": "user",
      "address_type": "mailing",
      "line1": "<street>",
      "city": "<city>",
      "state": "<state>",
      "postal_code": "<zip>",
      "country": "US",
      "phone": "<e164_phone>"
    }
  ],
  "rationale": "User confirmed filing the <option_1> LLC formation in <chosen_state>"
}' --agent
```

The payload must carry a non-empty `"rationale"` (with `--json`, it goes in the
body instead of a `--rationale` flag) — without it the submission is rejected
with a validation error and no filing is created.

For the valid no-25%-owner shape identified in Step 2, add a non-empty
`members` list to that same payload. Collect these formation-specific member
facts even though the individuals are not 25%+ beneficial owners:

- `legal_first_name` and `legal_last_name`
- `is_natural_person`
- residential `address` (`line1`, optional `line2`, `city`, `state`,
  `postal_code`, and `country`)
- `ownership_percent`
- `contact_full_name`
- optional `nationality`

Every member must include all required fields above, and the sum of
`ownership_percent` across the list must equal exactly 100. Do not include the
optional `ssn_last_4`; SSN remains browser-only and the CLI rejects SSN fields.
Do not add `responsible_party` or copy the controlling officer into `members`
unless the user confirms that person is actually an LLC member.

```json
"members": [
  {
    "legal_first_name": "<entity_legal_name_first_part>",
    "legal_last_name": "<entity_legal_name_remainder>",
    "is_natural_person": false,
    "address": {
      "line1": "<residential_street>",
      "city": "<city>",
      "state": "<state>",
      "postal_code": "<zip>",
      "country": "US"
    },
    "ownership_percent": 100,
    "contact_full_name": "<contact_full_name>"
  }
]
```

On success:
```
✓ Submitted to Ramp. Status: PENDING_REVIEW
  Note: SSN was handled in the Ramp application form, not by the CLI.
```

The returned `formation_submission_status` may be `PENDING_REVIEW` for the
normal waiting path, or `SUBMITTED` when pre-EIN early access is enabled and the
formation has been filed but the EIN has not been issued yet.

### 7. Poll for formation status

Ramp processes most filings within a few business days. Poll periodically:

```bash
ramp incorporation status --agent
```

States:
- `PENDING_REVIEW` → still processing
- `SUBMITTED` → filed with the state; limited pre-EIN access is available while waiting for EIN issuance
- `APPROVED` → EIN issued, Ramp backfill in progress
- `REJECTED` → see reason, follow recovery steps below

When `SUBMITTED`, continue the Ramp onboarding flow with the limited-access
annotation returned by `ramp incorporation status`; do not wait for `APPROVED`
unless the next action specifically requires the EIN-backed entity fields.

When reporting status, keep these three tracks separate:

- **Ramp financing application:** use `ramp applications progress`; `IN_REVIEW`
  / `WAIT_FOR_RAMP` means Ramp is reviewing the financing application.
- **Access:** use the `pre_ein` annotation from `ramp incorporation status`;
  `pre_ein.access = LIMITED` means limited pre-EIN access while EIN is pending.
- **Incorporation filing:** use `formation_submission_status`; `SUBMITTED`
  means filed with the state, and `APPROVED` means EIN issued / full access
  unblock is available.

While the provider is still incorporating (formation SUBMITTED but not yet
completed), do not act on or chase certificate-of-incorporation or EIN KYB
follow-ups — those are expected to be unavailable until formation completes.
Acknowledge them as pending and continue; do not surface them to the person as
action items yet.

Once `APPROVED`, Ramp automatically updates `legal_name`, `ein`,
`date_of_incorporation`, and `state_of_incorporation` into the financing
application.

### 8. Confirm blocker cleared

Re-query `GET /developer/v1/applications/progress` directly or check the Ramp
dashboard.

If the user is actively waiting for the incorporation blocker to clear, use the
application progress wait flag rather than a manual spin loop:

```bash
ramp applications progress --env production --agent \
  --wait_for_action COMPLETE_INCORPORATION --wait_interval 60 --wait_timeout 1800
```

Use this as a short operational wait after formation state changes. Do not leave
the CLI waiting for days; for provider processing delays, poll
`ramp incorporation status` periodically as described above.

The `COMPLETE_INCORPORATION` blocker should be gone. Normal flow resumes
(`INCOMPLETE_PAGE` blockers for remaining application sections).

### 9. Retrieve formation documents

```bash
ramp incorporation documents --agent
```

Returns articles of incorporation, EIN letter, and other formation docs.

## Worked Example

```bash
# 1. Check application progress
# GET /developer/v1/applications/progress
# → COMPLETE_INCORPORATION blocker, reason: NO_LEGAL_ENTITY

# 2. Research options
ramp incorporation states --agent
ramp incorporation industries search --q "saas restaurant" --agent
# → picks DE, NAICS 541511

# 3. Create applicant
ramp incorporation applicant create --agent

# 4. Confirm application progress no longer requires SSN entry.

# 5. Submit
ramp incorporation submit --json '{
  "state": "DE",
  "naics_code": "541511",
  "description": "SaaS platform for restaurant operations.",
  "name_options": [
    {"name": "Acme",        "entity_type_ending": "LLC"},
    {"name": "Acme Labs",   "entity_type_ending": "LLC"},
    {"name": "Acme Co",     "entity_type_ending": "LLC"}
  ],
  "addresses": [
    {"provider": "ramp", "address_type": "registered_agent"},
    {"provider": "user", "address_type": "mailing",
     "line1": "...", "city": "San Francisco", "state": "CA",
     "postal_code": "94105", "country": "US",
     "phone": "+14155550100"}
  ],
  "rationale": "User confirmed filing the Acme LLC formation in Delaware"
}' --agent
# → SUBMITTED (limited pre-EIN access; EIN still pending)

# 6. Days later — check status
ramp incorporation status --agent
# → APPROVED (EIN auto-backfilled by Ramp)

# 7. Confirm blocker cleared
# GET /developer/v1/applications/progress
# → No COMPLETE_INCORPORATION; INCOMPLETE_PAGE blockers for remaining sections

# 8. Get documents
ramp incorporation documents --agent
# → articles of incorporation, EIN letter
```

## Name Conflict Recovery

If `ramp incorporation status` returns `REJECTED` with `reason: NAME_CONFLICT`:

1. Generate 3 new LLC name options (e.g. add "Group", "Co", geographic suffix).
2. Re-run `ramp incorporation submit` with the new `name_options[]`.
3. Ramp treats the resubmission as a fresh name attempt.

## Gotchas

| Issue | Fix |
|-------|-----|
| SSN entry still required | Send the current Ramp form `deep_link_url`; do not run `ramp incorporation submit` until progress no longer requires SSN entry |
| `ssn` key in `--json` rejected | Never pass SSN in `--json`; use the Ramp form for SSN entry |
| `incorporation:write` scope missing | User must re-authorize OAuth with incorporation scopes via `ramp auth login`. **The user must open the Ramp email they receive and complete sign-in before authorization finishes.** |
| `No incorporation applicant exists for this business` | Do not retry submit first. Run `ramp incorporation applicant create --env production --country-of-residence US --agent`, then `ramp incorporation applicant get --env production --agent`, in the same authenticated terminal that will run submit. Then retry submit. |
| `ramp incorporation status` returns 404 `No incorporation formation exists` plus a generic auth-token hint | If `ramp auth status` confirms the current business-scoped OAuth session and `incorporation:read` / `incorporation:write`, treat this as the first-submission path and continue with applicant create/get. If auth is not clean, re-authenticate first. |
| Applicant retrieval succeeds but submit still says no applicant | Re-authenticate with the intended Ramp business and retry applicant create/get once. Do not add undocumented identifiers to the formation payload. If the public CLI error persists, direct the user to Ramp support with only the user-visible error message. |
| Multiple `ramp` binaries are installed | Use one explicit CLI path for every command in the applicant create/get + submit sequence; do not mix Homebrew and editable/uv-installed binaries. |
| Guidance asks for `members`, `responsible_party`, or SSN environment variables | Use the lean submit payload when the submitted financing application identifies an owner. Use `members` only for the confirmed no-25%-owner fallback; never send `responsible_party` or collect SSN environment variables. |
| No-25%-owner application needs formation members | After FA submission, confirm the controller is not a beneficial owner and `beneficial_owners` is empty; send a non-empty `members` list whose ownership totals 100 instead of retrying the lean payload |
| Formation company addresses | Send exactly two entries: `{"provider": "ramp", "address_type": "registered_agent"}` plus a `{"provider": "user", "address_type": "mailing", ...}` customer mailing address. |
| Country codes | Use `US` for mailing address country. Ramp defaults omitted country fields to `US` and currently rejects non-US values. |
| Formation takes days | Poll `ramp incorporation status` every few hours; do not re-submit while PENDING_REVIEW or SUBMITTED |
| Docs not available yet | Documents appear after APPROVED; poll `ramp incorporation documents` |

## If You Get Blocked

If the user wants to report an unresolved public CLI error, ask for consent and
have them approve the exact message before sending feedback:

```bash
ramp feedback "<user-approved description of the public CLI error>"
```

This sends the approved message to Ramp support. Do not include secrets,
resource identifiers, raw KYC output, or diagnostic artifacts.
