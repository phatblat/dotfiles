---
name: ramp-apply-for-account
area: Getting Started
supported_surfaces: [cli]
description: |-
  Start or complete a Ramp financing application. Use for application signup,
  missing information, documents, banking, follow-ups, progress checks, and
  clear handoffs between an agent and the person applying.
---

# Apply For A Ramp Account

Use the live `ramp applications` commands and responses as the source of truth.
Keep the conversation simple. Explain business or API terms only when needed.

## Start With A Choice

First determine whether the person wants to start a new application or continue
an existing one. Then offer a collaboration style:

- **Guided:** ask short questions one section at a time.
- **Use documents:** read only the files they provide, extract relevant facts,
  and ask them to confirm before writing.
- **Mostly in Ramp:** do what the agent can, then proactively provide direct
  Ramp links for the person to finish.

Recommend guided mode when they are unsure. They may switch modes at any time.

Use production by default — nearly everyone using this skill is filing a real
application, and every example below uses `--env production`. Sandbox is
available only when the user explicitly requests a test application: replace
`production` with `sandbox` in every command and confirmation, and never mix
environments within one application flow. Say plainly that production starts a
real signup and underwriting process.

## Start A New Application

Inspect the current payload shape:

```bash
ramp applications schema --env production --agent
ramp applications create --env production --example --agent
```

Ask: **"What email should receive the Ramp application invite?"**

Collect only the fields required to create the application. Use only facts the
person supplied or confirmed. Never treat example values as defaults.

Ask whether the business already has a formed legal entity with an EIN. If it
does not, set `needs_incorporation: true` in the create payload and do not send
formed-entity details such as legal name, EIN, incorporation date, or
incorporation state in the initial create request. The resulting
unformed-entity flow is handled in two phases: first collect and PATCH the
provisional incorporation preferences required by the financing application,
then after the applicant reviews and submits FA, use `ramp-incorporate` for
the actual formation filing. Incorporating through Ramp is not free — pricing
and details are the source of truth at
https://agents.ramp.com/docs/account/incorporate; when the business has no legal
entity yet, tell the person incorporation has a cost and offer to fetch that page
before they commit. Before running incorporation write commands,
confirm the CLI is authenticated as the newly-created applicant business; an
older agent-key session will operate on its older business instead.

Before sending, give one concise confirmation:

> Ready to send a real Ramp application invite to `<masked email>` for
> `<business name>` in production. This starts signup but does not submit the
> application. Should I send it now?

After confirmation:

```bash
ramp applications create --env production \
  --json '<confirmed payload>' --wait_for_auth --agent
```

The confirmed JSON payload must include a non-empty `"rationale"` key alongside
the application fields (e.g. `"rationale": "User confirmed sending the Ramp
application invite for <business name>"`) — without it the create is rejected
with a validation error and no invite is sent.

Keep the command running. **The flow is blocked until the recipient opens the
invite email and accepts it.** Lead with the email and say it plainly — do not
imply anything opens automatically on their end. Name the inbox:

> **I've sent an application invite email to `<applicant email>`. Open your email
> inbox now and accept the invite** — nothing pops up automatically. I'll wait
> right here until you do.

Then tell them what to do from the email:

1. Open the Ramp invite email in `<applicant email>`'s inbox (check spam if you
   don't see it).
2. Click the link in the email, then create an account or sign in.
3. Choose **Start application**.
4. Return here after the browser step completes.

Do not describe this as only a "browser" step or imply a window will open on its
own — the person must first open their email inbox and accept the invite.

The CLI saves scoped credentials when the browser callback succeeds. If it
returns `authenticated: false`, the application still exists. Run the returned
fallback login command, then continue below.

If the user interrupts `--wait_for_auth` after the invite is created, the CLI
returns `interrupted: true`, `authenticated: false`, and, when the API provided
one, `invite_link`. Treat this as a successful application creation with an
unfinished auth handoff: show the invite link, ask the recipient to finish the
Ramp browser step, and use the returned fallback command only if credentials are
still needed.

If creation returns a rate-limit error, explain when they can retry. Do not
automatically retry or change identities, sessions, or networks to evade it.

An existing Ramp email may continue an existing application instead of creating
a new one. Do not imply that a second application was created.

## Continue An Application

Check authorization:

```bash
ramp auth status --env production --agent
```

The normal workflow needs `applications:read`, `applications:write`, and
`bank_accounts:read`. If incorporation may be needed, also include
`incorporation:read` and `incorporation:write` so the `ramp-incorporate`
skill can continue without a second auth handoff. If missing:

```bash
ramp auth login --env production \
  --auth-level business \
  --scope applications:read \
  --scope applications:write \
  --scope bank_accounts:read \
  --scope incorporation:read \
  --scope incorporation:write
```

This opens a browser-based authorization. **The user must open the Ramp email
they receive and complete the sign-in step before authorization can finish.**
The CLI waits for the browser callback; do not proceed until it succeeds.

Any sanctioned connection user may authorize the intended business. If Ramp
shows a business chooser, ask them to select the business whose application
they want to complete. Read the application, state the returned legal business
name and masked applicant email, and ask them to confirm it is the intended
application before the first write. If it is not, stop and reauthorize the
correct business.

## Run The Progress Loop

Always start or resume with:

```bash
ramp applications progress --env production --agent
```

Inspect the full `required_actions`, `optional_actions`,
`ready_for_submission`, and status before acting.

When the next step is a known applicant browser action and the person is acting
now, use the progress command's wait flags instead of repeatedly polling by hand:

```bash
# After sending the person to complete phone verification
ramp applications progress --env production --agent \
  --wait_for_phone_verification --wait_interval 15 --wait_timeout 900

# After sending the person to complete Onfido / identity verification
ramp applications progress --env production --agent \
  --wait_for_identity_verification --wait_interval 15 --wait_timeout 900

# For any exact required-action enum, applicant-action enum, page_key, or section_key
ramp applications progress --env production --agent \
  --wait_for_action <action_or_key> --wait_interval 15 --wait_timeout 900
```

Use wait flags only after you have shown the required link or instructions and
the person has agreed to do that step now. If the wait times out, surface the
pending action from the CLI error, re-fetch progress if needed, and ask whether
they want more time or a fresh link. Do not use wait flags with `--dry_run`.

1. First look for independently actionable work, even if other required actions
   are owned by Ramp or the applicant.
2. If a required action is `COMPLETE_INCORPORATION` with provider `doola`, use
   the `ramp-incorporate` skill to file the LLC before continuing. For any
   other provider, explain that the incorporation provider is not supported by
   the CLI yet and show the current Ramp link if one is returned.
   If `ramp-incorporate` is not already installed in the active agent
   environment, fetch it from the same Ramp CLI binary and version you are using:
   `ramp skills show ramp-incorporate`. Do not search old local checkouts,
   prior Codex work directories, or other stale skill snapshots.
3. Do not use `WAIT_FOR_RAMP` alone as an incorporation signal; formed
   businesses also wait on ordinary Ramp review. If there is no active
   `COMPLETE_INCORPORATION` blocker, use `ramp-incorporate` only when the
   person explicitly asked to file an LLC for the current unformed-entity
   application, the application still shows `needs_incorporation=true` or no
   formed entity/EIN, and the submitted application is waiting on Ramp (usually
   `status`/`state` = `WAIT_FOR_RAMP`). Confirm the current business-scoped
   OAuth session before write commands. Do not wait for Ramp approval,
   underwriting, or identity review after submission in this explicitly
   unformed-entity path.
4. Complete independently actionable `actor=AGENT` work.
5. Re-fetch progress after every meaningful write.
6. For `actor=APPLICANT`, explain the step and show its current Ramp link.
7. If any remaining required action has `actor=RAMP`, explain that Ramp is
   reviewing or processing and stop before writing.
8. Show optional actions separately. They never block required work.

Do not stop at the first human action if other agent-owned work can be completed
independently. Treat Ramp-owned actions as stop conditions only after
incorporation and other independent agent-owned work have been handled.
Do not hand off an applicant-owned browser step while required agent-owned
application data is still visible and independently writable.

Continue until the agent has no remaining work, the person must act, Ramp owns
the next step, or the application is `APPROVED`, `REJECTED`, or `WITHDRAWN`.

When progress returns `ready_for_submission=true`, run
`ramp applications get --env production --agent` before telling the person the
application is ready. For `needs_incorporation=true` applications, verify that
`business.incorporation` contains the provisional entity type, filing state, and
intended filing date whenever `date_of_incorporation` is present in the live
application/edit schema. Progress may omit a validation issue for this field, so
do not treat missing progress validation as proof the intended date can be
skipped. If those fields are null or missing, collect and patch them first,
leaving EIN empty/null unless Ramp has already issued one. This check applies
even when the only remaining required action is `REVIEW_AND_SUBMIT`; do not send
the person to final review/submission while provisional incorporation fields are
still missing or unconfirmed.

After that check, `ready_for_submission=true` means the application is ready for
the person to review and submit in Ramp. The agent must not perform final
submission or accept legal agreements. Do not start incorporation formation yet;
show the submission link, wait for the person to submit, then re-fetch progress.
When the submitted application is waiting on Ramp (usually `WAIT_FOR_RAMP`),
start incorporation if the LLC still needs to be filed.

## Minimize Browser Touchpoints

During application data collection, the only forced browser touchpoints should
be:

- accepting the invite email;
- phone verification, when progress returns it;
- SSN entry;
- Onfido identity verification.

Everything else should be completed through the CLI when the API allows it. In
guided mode, collect all visible non-sensitive missing facts from the current
progress response before the next browser handoff. This includes general
details, principal business address, financial estimates, provisional
`business.incorporation` fields for `needs_incorporation=true` applications,
domain-mismatch explanation, and owner/controller fields such as title, birth
date, residential address, email, phone, role, and ownership percentage.

When every API-writable/non-sensitive application field has been submitted and
the only remaining applicant-owned actions are SSN entry and optionally phone
verification, present the returned Ramp form link(s) together so the person can
complete them in one browser session. If they are completing phone verification
or Onfido now, run the matching
`ramp applications progress --wait_for_phone_verification` or
`--wait_for_identity_verification` command so the agent resumes as soon as the
required action clears. After the wait returns, continue from the returned
progress payload as the new source of truth. Final review and submission is also
applicant-only, but do not send the person there until all API-writable data and
required browser verification steps are complete.

## Unformed Entity Incorporation Fields

For `needs_incorporation=true` applications, the financing application may still
require an **Incorporation** section before the person can submit FA. Treat those
fields as intended/provisional filing facts needed by FA, not proof that the
entity already exists.

Before surfacing phone verification, SSN entry, identity verification, or final
review/submission, inspect the live application edit schema and formation
reference data:

```bash
ramp applications get --env production --agent
ramp tools schema applications edit --env production --agent
ramp applications edit --env production --help
ramp incorporation states --env production --agent
ramp incorporation industries search --env production --q "<business keywords>" --agent
```

Use the edit schema as the source of truth for which provisional incorporation
fields are writable, but do not present unsupported formation types as options.
The current Ramp formation flow is LLC-only; if the application schema asks for
entity type, confirm the applicant wants an LLC and set the LLC value the schema
expects. If the applicant wants another entity type, stop and hand off to Ramp
or the team instead of continuing with `ramp-incorporate`. Use
`ramp incorporation states` to present valid filing states, and search
industries with business-specific keywords when an industry/NAICS field is
needed.

When the FA surface asks for business type and state:

- fill the intended entity type and state before FA submission;
- ask the user which valid state they want to incorporate in after fetching the
  available states;
- confirm the applicant wants to form an LLC before writing the entity type;
  the current Ramp formation flow does not support choosing other entity types;
- patch `date_of_incorporation` before FA submission whenever the current
  application/edit schema exposes it for the unformed-entity provisional FA
  section. Treat it as the intended filing date, confirm that the user is
  providing an intended filing date, and ask whether it should be today's date,
  naming the exact date in the user's local timezone. Do not infer or reuse an
  actual incorporation date because Ramp backfills that after approval;
- leave EIN empty/null; treat it as optional here, but do not provide it in
  tool calls for `needs_incorporation=true` because Ramp backfills it after
  incorporation completes;
- do not skip this step because Doola formation has not been submitted yet;
- after the person submits FA, use `ramp-incorporate` for the actual Doola
  formation filing.

## Make Human Handoffs Obvious

Whenever a current `deep_link_url` is returned, show it prominently:

> **Required human step:** Verify your identity
>
> **Open in Ramp:** `<deep_link_url>`

For an agent-owned step that also has a link:

> I can complete this here. If you prefer to take over:
>
> **Open in Ramp (optional):** `<deep_link_url>`

Be proactive; do not wait for the person to ask for the link. Say whether the
link is required or an optional takeover. If it may be stale, fetch progress or
follow-ups again and use the newly returned URL. Never invent a Ramp or
third-party link.

## SSN — Browser Handoff Only

**Never ask for or accept SSN (last-4 or full 9-digit) in chat, CLI prompts, env vars, or `--json`.** SSN entry must happen exclusively through the Ramp browser form link that Ramp returns, including when the `ramp-incorporate` workflow is active.

Fill all other application fields programmatically via the CLI before asking the
person to handle SSN in Ramp. If `validation_issues` for
`controlling_officer` or `beneficial_owners` include both SSN and non-sensitive
missing fields such as address, birth date, title, email, phone, or ownership
percentage, collect and PATCH the non-sensitive fields first, then re-fetch
progress. Show the SSN browser link only after those non-sensitive fields are
submitted and the only other remaining applicant-owned action is phone
verification.

When SSN collection is needed, there are two cases:

**Last-4 case (Leaders & Owners — `controlling_officer` / `beneficial_owners`):**
When `ramp applications progress` returns a required action for the
`controlling_officer` or `beneficial_owners` section that returns a non-null
`deep_link_url`, present that link as the required way to enter SSN:

> **Required step — enter SSN in Ramp:**
>
> **Open in Ramp:** `<deep_link_url>`
>
> Complete SSN entry in the browser, then return here and let me know so I can
> re-fetch your application progress.

If the required action for `controlling_officer` or `beneficial_owners` returns
a **null** `deep_link_url` (feature not yet deployed), do **not** ask for SSN
in chat. Instead, tell the user:

> SSN must be entered directly in the Ramp application in your browser. Please
> open your Ramp application, navigate to the Leaders & Owners section, and
> complete SSN entry there. Let me know when done and I will re-fetch progress.

**Full-9 case (KYC follow-up):**
When `ramp applications followups` returns a follow-up with `reason` of
`KYC_SSN_VERIFICATION` or `KYC_SSN_FULL_9_VERIFICATION` that returns a
non-null `deep_link_url`, present that link prominently:

> **Required step — verify your full SSN in Ramp:**
>
> **Open in Ramp:** `<deep_link_url>`
>
> Complete SSN verification in the browser, then return here and let me know so
> I can re-fetch your follow-ups.

After the user confirms they have finished the browser step, re-fetch progress
or follow-ups and continue. When the browser step maps to a progress required
action, prefer `ramp applications progress --wait_for_action <page_key_or_section_key>`
while the user completes it. Never invent a link; use only the `deep_link_url`
returned by the API.

## Ask Only For The Next Missing Facts

Use `page_key`, `section_key`, `guidance`, follow-up prompts, accepted document
types, and live command help to explain:

- what is missing;
- why Ramp needs it now;
- where the person can usually find it; and
- whether they can complete it directly in Ramp.

Batch related, non-sensitive questions from all current agent-owned required
actions so the person does not have to bounce between Ramp and chat. Keep
sensitive requests separate.
Prefer plain questions such as:

- "What is the legal name shown on the business's formation or tax document?"
- "What email should we use for this owner?"
- "Is the controlling officer also an owner? If so, what percentage do they own?"
- "What is the controlling officer's residential address?"
- "Ramp currently supports LLC formation here. Do you want an LLC, and which
  valid filing state should we use?"
- "Would you like to open a Ramp checking account, add an external account, or
  do both?"

## Owners And Control

Early-stage businesses often have a controlling officer who is also a
beneficial owner. Ask about role and ownership separately before writing the
Leaders & Owners fields.

When the controlling officer owns 25% or more of the business, include both
`controlling_officer.is_beneficial_owner: true` and
`controlling_officer.ownership_percentage` as a whole number from 25 to 100.
Do not duplicate the same person in `beneficial_owners` just because they are
both the controller and a 25%+ owner. Put other 25%+ owners in
`beneficial_owners`, and include each owner's `ownership_percentage`.

Before calling `ramp applications edit`, normalize owner/controller emails
case-insensitively and shape the desired payload:

- if any `beneficial_owners[*].email` matches `controlling_officer.email`, merge
  the non-sensitive owner fields into `controlling_officer`;
- set `controlling_officer.is_beneficial_owner: true`;
- set `controlling_officer.ownership_percentage` when known;
- remove that matching entry from `beneficial_owners`;
- never retry by appending the same beneficial owner again; fetch current state
  and PATCH the deduped desired state.

Example for a sole owner who is also the controlling officer:

```json
{
  "controlling_officer": {
    "email": "owner@example.com",
    "is_beneficial_owner": true,
    "ownership_percentage": 100
  },
  "beneficial_owners": []
}
```

When the controlling officer owns less than 25%, capture their
`controlling_officer.ownership_percentage` if the field is available, but do not
mark them as a beneficial owner. Set
`controlling_officer.is_beneficial_owner: false` when the field is present and
list only 25%+ owners in `beneficial_owners`.

If the controlling officer does not own the business, set
`controlling_officer.is_beneficial_owner: false` when the field is present and
list the actual beneficial owners separately. Only send
`ownership_acknowledgement` after the person explicitly confirms that all
25%+ beneficial owners have been captured.

When no individual owns 25% or more, require that explicit confirmation before
writing an empty owner list. Set `beneficial_owners: []`,
`controlling_officer.is_beneficial_owner: false`, and
`ownership_acknowledgement: CONFIRM_NO_INDIVIDUAL_OWNS_25_PCT`. Do not use that
acknowledgement merely because no owner was entered yet. This ownership shape is
valid for the financing application, but `ramp-incorporate` will separately
collect the LLC members required for formation after the application is
submitted.

If the applicant's business email domain does not match the business website
domain, surface that mismatch plainly before writing it, and ask for a brief
reason (for example, a personal email or a parent-company domain). Do not block
on it — capture the explanation and continue.

Useful sources include formation documents, an IRS EIN letter, a cap table,
financial statements, bank statements, and official address records. These are
examples, not requirements.

If several sections need documents, offer to use a private folder chosen by the
person. Read only files intentionally provided for this application. Do not scan
unrelated directories or write extracted PII, credentials, OTPs, or assembled
application payloads to disk.

## Record Agent Context When Supported

Before each generated mutation, inspect its live schema or help. When it exposes
the following fields, include both:

- `user_prompt`: the person's natural-language request that led to the write.
- `data_source_summary`: a short description of where the written facts came
  from.

Keep the source summary specific but free of sensitive values. Examples:

- `Legal name and EIN from the IRS letter provided by the user.`
- `Revenue confirmed by the user from QuickBooks.`
- `Document selected and authorized by the user for this follow-up.`

Use the current generated command options or JSON body. If the live operation
does not expose these fields, omit them rather than inventing unsupported
arguments. Do not invent provenance.

## Update Application Data

Read current state and schema first:

```bash
ramp applications get --env production --agent
ramp tools schema applications edit --env production --agent
ramp applications edit --env production --help
```

PATCH only supplied or source-backed fields. Omit unknown fields:

```bash
ramp applications edit --env production \
  --json '{
    "<field>":"<confirmed value>"
  }' --agent
ramp applications progress --env production --agent
```

When the live edit schema exposes agent-context fields, add the `user_prompt`
and `data_source_summary` described above to the JSON body.

Treat validation errors as correctable input issues. Ask for the rejected value;
do not guess or repeatedly PATCH alternatives.

## Handle Follow-Ups

```bash
ramp applications followups --env production --agent
```

Inspect `actor`, `type`, `status`, `is_complete`, `is_required`, `prompt`,
`description`, `deep_link_url`, `accepted_document_types`, and
`selected_document_type`.

- Skip completed follow-ups.
- Label `is_required=false` as optional.
- For `REVISION_REQUESTED`, explain the current request and reassess the prior
  response.
- If the application is still in the Ramp incorporation flow (`COMPLETE_INCORPORATION`
  is active, or `ramp incorporation status` is still pre-`APPROVED`), do not
  surface certificate-of-incorporation, articles-of-incorporation, or EIN/EIN
  letter KYB follow-ups as current user action items yet. Acknowledge them as
  pending formation outputs and continue with any unrelated work.
- If any follow-up has `actor=RAMP`, explain that Ramp owns the next step and
  stop before writing.
- Never mutate an applicant-owned follow-up. Show its link.
- Complete agent-owned follow-ups before asking the person to handle unrelated
  applicant-owned work.

Text response:

```bash
ramp applications update-followup <followup_id> --env production \
  --json '{
    "response_text":"<confirmed response>"
  }' --agent
```

When the live follow-up schema exposes agent-context fields, add them to the
JSON body.

For a document follow-up, prefer a matching `accepted_document_types` value. If
the prompt or description requests a bespoke type, use that exact
human-confirmed type even when it is not listed. Do not invent or generalize
types. If `selected_document_type` already matches, do not update it again.
Upload only the file the person selected and explicitly authorized; selecting a
type does not upload the file.

When `selected_document_type` must be set or changed:

```bash
ramp applications update-followup <followup_id> --env production \
  --json '{"selected_document_type":"<confirmed type>"}' --agent
```

```bash
ramp applications upload --env production \
  --file <path> --purpose FOLLOWUP --followup_id <followup_id> --agent
ramp applications followups --env production --agent
```

When the live upload schema exposes agent-context fields, include them using its
generated options.

After all required follow-ups are complete and the response reports
`is_submission_ready=true`, submit the follow-up package and refresh progress:

```bash
ramp applications submit --env production --agent
ramp applications progress --env production --agent
```

When the live submit operation exposes agent-context fields, include them using
its generated options. This is not final application submission.

## Handle Banking

Banking has three possible paths:

- open Ramp checking;
- link one or more external accounts in Ramp; or
- add one or more manual accounts through the agent workflow.

Ask which path the person wants. Ramp checking and external accounts are not
mutually exclusive.

For provider linking, show the current Ramp link as a required or optional human
handoff. Never ask for online-banking credentials.

For a manual account:

1. List current accounts and documents before making changes.
2. Reuse an existing applicant-confirmed manual account when it matches the
   intended account; associate uploads with its `manual_bank_account_id`.
3. Add a manual account only when the person explicitly wants a new one, using
   details they provided for this application and agent context when exposed.
4. Upload only the supporting documents missing for the selected account.
5. Re-list accounts and documents, then refresh progress.

Paginate until `pagination.next_cursor` is null. Never alter a cursor.

For the standard manual-statement path, match documents by
`manual_bank_account_id`. Three active `BANK_STATEMENT` documents complete that
path; three is not a general upload maximum. Do not upload extras after the
requirement is met.

For each missing statement:

```bash
ramp applications upload --env production \
  --file <statement_path> --purpose BANK_STATEMENT \
  --manual_bank_account_id <account_id> --agent
ramp applications documents --env production --page_size 100 --agent
```

When the live upload schema exposes agent-context fields, include them using its
generated options. Recount active statements for that account after each upload.

Adding accounts does not complete a `BANK_ACCOUNT_LINK_REQUEST` follow-up. After
refreshing the account list, ask the person to confirm that there are no more
accounts to link. Only after explicit confirmation, update that follow-up:

```bash
ramp applications update-followup <followup_id> --env production \
  --json '{
    "no_more_accounts_to_link":true
  }' --agent
ramp applications followups --env production --agent
ramp applications progress --env production --agent
```

When the live follow-up schema exposes agent-context fields, include the
person's confirmation as `user_prompt` and identify the person as the source in
`data_source_summary`.

Do not use this response to bypass an account-linking flow the person still
wants to complete.

If an active agent-managed Ramp account number becomes available and the person
asks for receiving details, use `ramp treasury account-numbers --env production
--agent` with the narrow `agent_account_numbers:read` scope. Treat returned
account and routing numbers as sensitive: show them only when requested and do
not repeat them in status summaries.

## Safety Boundaries

- Never invent application facts or sources.
- Never request full government IDs, OTPs, online-banking credentials, or other
  secrets in chat.
- Never collect SSN (last-4 or full 9-digit) in chat; always hand off to the
  returned `deep_link_url` as described in the **SSN — Browser Handoff Only**
  section above.
- Mask sensitive values in confirmations and summaries.
- Do not use `--dry_run` with sensitive data because it prints the request.
- The person must accept invitations, complete applicant-owned identity steps,
  accept legal agreements, review the application, and submit it.
- An agent may transmit an explicitly selected identity document only when the
  API marks that follow-up `actor=AGENT`; Ramp evaluates the document.
- If sanctioned browser, email, or SMS access exists and the person authorizes
  it, the agent may assist outside this API workflow. This is not officially
  supported and must not be assumed.

## If You Get Blocked

If the user wants to report an unresolved public CLI error, ask for consent and
have them approve the exact message before sending feedback:

```bash
ramp feedback "<user-approved description of the public CLI error>"
```

This sends the approved message to Ramp support. Do not include secrets,
resource identifiers, raw application output, or diagnostic artifacts.

## Optional Goal And Monitoring Examples

When the agent environment supports `/goal`, suggest:

```text
/goal Help me finish my Ramp application. Complete agent-owned steps, show me
links for human steps, and stop before final submission.
```

When it supports `/loop`, suggest:

```text
/loop Check my Ramp application every 30 minutes. Complete agent-owned
follow-ups that need no new information, and tell me when I need to act or when
the application is approved.
```

A loop must not invent information, bypass confirmation, perform final
submission, or retry a rate limit.
