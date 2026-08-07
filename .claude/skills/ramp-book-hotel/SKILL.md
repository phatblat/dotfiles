---
name: ramp-book-hotel
area: Travel
supported_surfaces: [cli, mcp]
description: "Searches and books hotels conversationally through the Ramp CLI: resolves the traveler, searches paginated hotel inventory, compares the selected room-rate returned for each hotel, previews the selected rate, and books only after explicit approval. Use when someone wants to find, compare, or book a hotel or lodging. Not for flight booking, cancellations, changes, refunds, or car rentals."
user-invocable: true
---

# Book a Hotel

The user describes a stay in plain words. Turn that into `ramp travel` commands, run them, and
show clean results. Never show or ask the user to type a CLI command; talk like a travel helper
(`Searching hotels near the Chicago office, Aug 10-13...`), not about tools or flags.

The steps, phases, checklists, field names, and command names in this guide are your internal
scaffolding; never surface them to the user. Reason through them silently. Never mention this
skill, its instructions or specification, whether you are following or complying with it, or how
an internal tool name maps to a CLI command. Do not narrate command-name or alias reconciliation.
Give only concise, user-relevant action and result updates.

## Scope and safety

- Use `ramp travel search-hotel` to search, `ramp travel hotel-rates` to fetch the selected
  hotel's rates, and `ramp travel book-hotel` to preview and book.
- Always use `--output json`; build a readable comparison instead of showing raw JSON.
- Always include a rationale that consistently names the destination and stay dates.
- Keep each tool step to one direct `ramp` command. Read IDs from the prior JSON response and pass
  the exact literal value as the next positional argument. Never write response JSON to temporary
  files, invoke Python or `jq` to recover an ID, use nested command substitution, or pipe through
  `tail`/other shell filters. Keep the ID in context and call the next command directly.
- Omit flags whose documented defaults match the request, such as `--num_adults 1`; do not make
  commands longer by restating defaults.
- Always follow this order: `search-hotel` → traveler selects a hotel → `hotel-rates` → traveler
  selects a room/rate → `book-hotel` preview → explicit approval → `book-hotel --confirm`.
- A hotel booking spends real money. Always preview first and wait for explicit confirmation.
- Never reuse an amount from search as `expected_total_amount`; only use the fresh preview's
  exact `total_amount`.
- A selected fund is part of the approved preview state. Never add or change
  `--spend_allocation_id` only at confirmation: preview again with the exact selected `fund_uuid`,
  present any changed total/policy/approval result, get explicit approval, then confirm with that
  same fund UUID. Any fund change requires another preview.
- Search result rate summaries are not selectable booking inventory. Pass the selected hotel's
  `id` to `hotel-rates`, then book only a literal selected `all_rates[].rates[].id` it returns.
- Treat relevant `external_agent_messages` from search, rates, preview, and confirm as service
  guidance and surface them plainly.
- If Ramp reports that hotel search or booking is unavailable, explain that it
  is not currently enabled for this Ramp account. Do not fall back
  to legacy hotel tools or claim that no inventory exists.

## Resolve the traveler

For self-booking, omit `traveler_user_id`. Before searching, check the traveler's profile:

```bash
ramp travel profile --output json \
  --rationale "check the traveler profile for the Chicago hotel stay, Aug 10-13"
```

If `has_profile` is false, collect the required identity and contact details together and call
`ramp travel profile-update`. Continue only after the profile update succeeds. This profile
preflight happens before search, not only at checkout.

Only book for another person when the requester explicitly asks. Resolve that person first:

```bash
ramp users list --name_search "Taylor Smith" --page_size 5 --output json \
  --rationale "resolve the traveler for the Chicago hotel stay, Aug 10-13"
```

If multiple people match, ask the requester to choose. Pass the selected user UUID to `travel
profile`, the fresh `travel search-hotel` call, `travel hotel-rates`, and both `travel book-hotel`
calls. Cursor pages use the cached traveler from the original search, so do not resend or change
the traveler there. Never silently switch to the requester when lookup or authorization fails.

## Gather the stay

Required details are destination, check-in date, and check-out date. Use the traveler's words for
a city, neighborhood, address, landmark, or office location. Resolve relative dates to
`YYYY-MM-DD` and repeat the dates back so mistakes surface before searching. Default to one adult;
only set another count when the traveler asks.

Ask for all genuinely missing required details in one message. Do not ask for preferences such as
hotel chain, amenities, or refundability unless the traveler made them important.

## Search hotels

```bash
ramp travel search-hotel --output json \
  --location_query "Chicago office" \
  --check_in_date 2026-08-10 --check_out_date 2026-08-13 \
  --rationale "search hotels for the Chicago stay, Aug 10-13"
```

Use `--location_query` for the destination context (city, neighborhood, office, landmark, or
address). When the traveler asks for a specific property, also pass its exact name with
`--hotel_name` while preserving the destination context.

```bash
ramp travel search-hotel --output json \
  --location_query "Lower Manhattan" --hotel_name "citizenM New York Bowery" \
  --check_in_date 2026-08-10 --check_out_date 2026-08-13 \
  --rationale "search for citizenM New York Bowery for the Manhattan stay, Aug 10-13"
```

Add `--traveler_user_id` only for delegated booking. Add `--num_adults` only when it differs from
one. The default page is ten hotels; `--limit` can request 1-10.

When the traveler explicitly requests supported filtering or ordering, send one complete `--json`
request because `filters` and `sort` are structured rather than standalone flags. Supported
filters are `star_ratings`, `brand_ids`, `amenity_ids`, and `min_review_rating`. Supported sort
keys are `DISTANCE`, `LOWEST_PRICE`, `TIME`, `WEIGHTED`, `MOST_POPULAR`, and `STAR_RATING`, with
`ASC` or `DESC`. Do not invent brand or amenity IDs; omit criteria that cannot be represented with
known literal values. Preserve destination, dates, traveler, adult count, limit, hotel name, and
rationale in the JSON body when applicable; omit adult count and limit when their defaults match.

`next_cursor` is opaque. If the traveler wants more results, call search with that value unchanged
as `--cursor` and a rationale; omit the original search fields because Ramp reads
the cached result. Preserve a non-default `--limit` when consistent page size matters. Append the
new hotels; never inspect, edit, synthesize, or reuse a cursor with a different search.

Use `total_count` and the number displayed so the traveler knows when more results are available.

An empty `hotels` list means no matching inventory. Offer to adjust the location or dates. Surface
`policy_summary` before the table when present; it is Ramp's authoritative summary of what this
traveler may book.

## Present the hotel comparison

Search follows the Ramp web flow and returns zero or one selected/best room-rate for each hotel
inside `rates`. It does **not** return every available room or rate. Render exactly one initial
comparison table. The full column order is:

| # | Hotel | Rating | Chain | Nightly (pre-tax) | All-in total | Policy | Loyalty program | Notes |
|---|-------|--------|-------|---------------------|--------------|--------|-----------------|-------|
| 1 | Four Seasons Chicago | 5-star | Four Seasons | $245 USD | $812 USD | In policy | Four Seasons Preferred Partner | 12 min walk; Company preferred |

Populate it only from returned metadata:

- Always show `#`, `Hotel`, `Rating`, `Nightly (pre-tax)`, `All-in total`, and `Policy`.
- `Chain`, `Loyalty program`, and `Notes` are optional columns. Omit an optional column completely
  when every row on the displayed page would be `-`. If at least one row has a meaningful value,
  keep the column in the order above and use `-` for individual rows without a value.
- **Rating:** use only `star_rating`, formatted as `4-star`, `5-star`, etc. Never show
  `review_rating` values such as `9.4`.
- **Chain:** show a real `chain` name such as `Four Seasons`. Render missing, blank, or placeholder
  values such as `Default Chain` as `-`.
- **Nightly (pre-tax):** show `nightly_amount` exactly as returned with `currency`. It is the base
  nightly amount before taxes and fees, matching web's `/night` price.
- **All-in total:** show `total_amount` exactly as returned. It is the full-stay total including
  taxes and fees; never derive it by multiplying the nightly amount or add taxes/fees yourself.
  Show `currency`.
- **Policy:** keep it concise: `In policy`, `Out of policy: <short violation>`, or `-` when no
  verdict is available. Trust the returned policy verdict and violations; do not infer policy from
  or reverse-engineer it from displayed prices. Use `policy_summary` for broader policy context.
- **Loyalty program:** show `loyalty_program` when present; otherwise show `-`. Do not replace a
  missing program with generic eligibility or points-earning prose.
- **Notes:** combine `office_travel_time_minutes` with `office_travel_mode` (for example,
  `12 min walk`), `coworker_booking_count` when nonzero, and `Company preferred` when
  `is_company_preferred=true`, separated by `; `. Show `-` when none is present. Do not call travel
  time a distance. Use hotel `address` to disambiguate similar properties; mention relevant
  `hotel_amenities` only when they match a stated preference.
- If `rates=[]`, show `-` for price, policy, and loyalty cells and note `No current summary rate`.
  Never index the first rate unless it exists; the traveler can still select the hotel and fetch
  complete rates.
- Keep a private display-number-to-hotel-`id` map. Never print hotel IDs unless asked.
- Do not show a second room/rate table during this initial comparison. Do not show `room_name`,
  `refundability`, or `cancellation_policy` yet; reserve them for the selected-hotel details.

Wait for the traveler to select a hotel option. If their choice is ambiguous, confirm the hotel,
nightly amount, and all-in total. Do not preview or book the search result's summary rate.

## Fetch and present selected-hotel rates

Call `hotel-rates` with the literal hotel `id` from search and the same dates, adult count, and
traveler target:

```bash
ramp travel hotel-rates "<selected_hotel_id>" --output json \
  --check_in_date 2026-08-10 --check_out_date 2026-08-13 \
  --rationale "fetch current rooms and rates for the selected Chicago hotel, Aug 10-13"
```

For delegated booking, pass the same `--traveler_user_id`. Keep `--num_adults` consistent with
search.

Render one row for every returned `all_rates[].rates[]` option:

| # | Room | Nightly (pre-tax) | All-in nightly | All-in total | Payment | Refundability | Cancellation | Policy | Loyalty | Notes |
|---|------|---------------------|----------------|--------------|---------|---------------|--------------|--------|---------|-------|
| 1 | Deluxe King | $245 USD | $271 USD | $812 USD | Pay later | Refundable | Free until Aug 8 | In policy | Four Seasons | Recommended; Company preferred |

- Use the room group's `room_name`, `room_description`, and `room_amenities`. Mark a group as
  recommended only when it also appears in `recommended_rates`; do not infer recommendations from
  list order or `best_rate`. `best_rate` is the lowest-total option within that room group, not a
  global recommendation.
- Show each rate's `nightly_amount`, `all_in_nightly_amount`, `total_amount`, `payment_type`,
  `refundability`, and `cancellation_policy` when present. Show amount strings exactly as returned
  and include the separate `currency` once; do not append it when the amount already includes it.
- Keep policy concise in the table and surface full `policy_violations` when the traveler compares
  or selects an out-of-policy rate.
- For loyalty, show `loyalty_program` and `earns_loyalty_points` when relevant. Clearly flag
  `loyalty_required=true` and stop before preview when `loyalty_eligible=false` until the
  membership is corrected.
- Put `is_company_preferred`, `is_corporate_rate`, and useful room amenities in Notes when
  present. `has_corporate_rates` is context, not proof every rate is corporate.
- Keep a private display-number-to-literal-rate-`id` map. Never use a room ID, hotel ID, or search
  summary rate ID for booking.
- Use top-level `hotel` metadata to reconfirm the selected property. `has_corporate_rates` is
  hotel-level context, while each rate's `is_corporate_rate` identifies the actual corporate rate.

These rates are current options, not quotes. Wait for the traveler to select one exact room/rate;
never guess or default to the first or recommended row.

## Preview the selected rate

Call `book-hotel` without `--confirm`. Its positional values are the literal selected hotel ID
from search and selected rate ID from `hotel-rates`. Pass the same stay dates used to fetch the
rate:

```bash
ramp travel book-hotel "<selected_hotel_id>" "<selected_rate_id>" --output json \
  --check_in_date 2026-08-10 --check_out_date 2026-08-13 \
  --rationale "preview the selected Chicago hotel rate, Aug 10-13"
```

For delegated booking, pass the same `--traveler_user_id`. If Ramp says the rate expired or is
missing from cache, start a fresh `search-hotel`; if the rate mismatches the selected hotel or stay
dates, call `hotel-rates` again for that hotel/current dates. Never retry an old rate or silently
choose another.

The preview is authoritative and may differ from the rates response. Present:

- hotel, room, and stay dates
- `nightly_rate` and exact all-in `total_amount`
- `in_policy` and every `policy_violations` entry
- `requires_approval` and each `approval_steps` entry
- every `eligible_funds` option: `fund_name` and available balance/spending limit when present;
  keep a private display-number-to-`fund_uuid` map rather than printing UUIDs
- matching `loyalty_programs`: meaningful `display_name` and `loyalty_number` values that Ramp will
  submit on confirm

Present funds without internal IDs:

| # | Fund | Available balance | Spending limit |
|---|------|-------------------|----------------|
| 1 | Client Travel | $1,500 USD | $5,000 USD |

Keep the display-number-to-`fund_uuid` map private. For loyalty memberships, show `display_name`
and only the last four characters of `loyalty_number` unless the traveler explicitly asks for the
full saved number; never display `loyalty_program_id` or `logo` as text.

Carry forward refundability, cancellation, and payment details from the selected rate. If that
rate requires loyalty but the traveler is not eligible, stop before preview and ask them to
correct the membership or choose another rate. Use preview `loyalty_programs` to verify which saved
matching membership Ramp will submit, rather than treating the rate's generic program name as
proof of enrollment.

If the preview is out of policy, show every returned violation and ask why the traveler needs that
rate. Keep their exact justification as `oop_reason`; Ramp requires `--oop_reason` on confirmation
for an out-of-policy quote and approvers see it. `reason` is a separate optional general booking
note; include `--reason` only when the traveler volunteered one.

If the traveler explicitly selected a known fund before preview, pass its UUID as
`--spend_allocation_id`. Otherwise preview without a fund, present every eligible choice, and ask
whether to use one or request a new allocation. If they choose a returned fund, repeat the preview
with its literal `fund_uuid` as `--spend_allocation_id`, present any changed approval result, and
get explicit approval of that final preview. Confirm with the same fund. Omitting the flag on
confirm requests a new allocation. Approval requirements come from `requires_approval` and
`approval_steps` and can differ depending on fund selection.

If the traveler selected an existing trip, keep its literal UUID in context but do not send
`--trip_id` during preview: Ramp only resolves it during confirm. A missing, invalid, or other-user
trip is ignored and Ramp auto-selects or creates one. Verify the resulting `trip_id`/`trip_name`
after booking when attachment matters. Omitting `--confirm` is the preview flow.

Finish with an explicit confirmation question containing the hotel, room, dates, refundability,
cancellation terms, all-in total, policy/approval state, matching loyalty membership, selected fund
behavior, and OOP justification when applicable. Stop and wait for a clear yes.

## Confirm only after explicit approval

Use the same hotel ID, rate ID, dates, traveler, and fund selection from the approved final preview.
Add `--confirm` and the preview's exact `total_amount`:

```bash
ramp travel book-hotel "<selected_hotel_id>" "<selected_rate_id>" --confirm \
  --check_in_date 2026-08-10 --check_out_date 2026-08-13 \
  --expected_total_amount '<preview_total_amount>' --output json \
  --rationale "book the selected Chicago hotel rate; traveler approved the preview"
```

Add optional confirmation flags only when applicable:

- `--traveler_user_id '<traveler_uuid>'`: exact delegated traveler UUID used for fresh search,
  rates, and preview.
- `--spend_allocation_id '<fund_uuid>'`: exact private UUID for the fund selected from the final
  preview; omit to request a new allocation.
- `--trip_id '<trip_uuid>'`: exact existing trip UUID explicitly selected by the traveler; omit to
  let Ramp auto-select or create a trip. This is the step where Ramp resolves it.
- `--oop_reason '<traveler_justification>'`: exact justification collected after an out-of-policy
  preview; required only when `in_policy=false`.
- `--reason '<booking_note>'`: separate optional general note, only when volunteered by the
  traveler. Never repurpose it as the OOP justification.

Keep any collected OOP justification in context through a fund or price re-preview, but send it
only on confirmation. If the new preview changes policy violations materially, reconfirm that the
traveler's justification still applies.

Single-quote currency strings containing `$` so the shell does not expand them. Never normalize,
reformat, or recalculate `expected_total_amount`.

If confirmation reports a changed total, do not book at the new price. Run a new preview, present
the new nightly/all-in amounts and any changed policy terms, then get explicit approval again. For
missing/expired cache mappings, start a fresh search; for hotel/date mismatches, fetch fresh rates
for the selected hotel/current dates. Treat feature-disabled errors separately from no results.

On a successful confirmation, present `booking.booking_request_id`, lowercase `booking.status`,
`booking.total_amount`, and `booking.next_steps` before verification. Do not call the reservation
confirmed merely because `booked=true`.

## Verify the booking request

The confirm response's `booked=true` means a booking request was created, not necessarily that the
hotel is confirmed. Show the returned booking status and approval state accurately. Verify with:

```bash
ramp travel bookings --output json \
  --rationale "verify the Chicago hotel booking request, Aug 10-13"
```

For delegated booking, pass the same traveler UUID. The default call includes current/upcoming
hotels, flights, and cars; inspect the hotel results and match using `hotel_name`, dates,
`room_type`, and the most recent `booked_at`. Use returned `trip_id` and `trip_name` to verify trip
attachment when needed.

The submit response's nested `booking.status` is lowercase (`pending_approval`, `approved`,
`booked`, or `rejected`). The bookings response uses uppercase request/reservation states:

- `CONFIRMED`: report the reservation as confirmed.
- `PENDING_APPROVAL`: report that the request is awaiting approval, not booked.
- `PROCESSING`: report that fulfillment is still processing and check again later.
- `FAILED`: show `error_message` and address the stated issue before retrying.
- `CANCELLED`: report that the request/reservation was cancelled.
- `REJECTED`: report that the request was rejected.

Default bookings lookup excludes unsuccessful `FAILED`, `CANCELLED`, and `REJECTED` requests. Only
repeat it with `--include_failed` when diagnosing an explicitly unsuccessful attempt; do not use
that flag for normal post-confirm verification.

For cancellations, changes, or refunds, hand off to the Ramp web app; do not submit another booking.
