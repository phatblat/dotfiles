# Exa `/search` tuning

Verified against `https://exa.ai/docs/reference/search-api-guide-for-coding-agents`
on 2026-07-25. If the docs contradict this file, the docs win.

## Choosing `type`

The script defaults to `auto`. Escalate only with a reason you can state.

| Query shape | Type | Latency | Why |
|---|---|---|---|
| Quick factual lookup, one known answer | `instant` | ~250ms | Depth buys nothing; latency is the only cost that matters |
| Slightly broader lookup, still single-answer | `fast` | ~450ms | |
| Normal doc/example lookup | `auto` | ~1s | The default for a reason |
| Light multi-angle lookup | `deep-lite` | ~4s | |
| Comparison across sources, "which of these", synthesis | `deep` | 4-15s | Runs multiple query angles and ranks the combined set |
| Hard multi-step research, conflicting sources | `deep-reasoning` | 12-40s | Expensive — justify before using |

## Filters

**`--domains` / `--exclude`** map to `includeDomains` / `excludeDomains` (max
1200 each). Use for authoritative pinning: `docs.rs,crates.io` for Rust crates,
`nodejs.org,developer.mozilla.org` for JS runtime questions, `github.com` when
you want source over blogposts.

Don't reach for them reflexively — Exa's neural search usually finds the right
sources unaided, and over-restricting produces empty results. `--exclude` also
pairs with `--domains` to include a domain but drop a subdomain: include
`vercel.com`, exclude `community.vercel.com`.

**`--since YYYY-MM-DD`** maps to `startPublishedDate` (ISO 8601; the script
appends `T00:00:00.000Z`). `endPublishedDate` also exists but is not exposed —
add a flag if you need it. This matters most for fast-moving libraries where a
two-year-old answer is actively wrong.

**`--chars`** maps to `contents.highlights.maxCharacters`, capping each result's
highlight. The script defaults to 600. **Do not remove this cap.** Uncapped
highlights on `github.com` PR and issue pages return the entire review thread —
measured at ~15KB for four results versus ~2.8KB capped, for the same answer.

## Not exposed by the script, and why

- `text` — whole-page content. Highlights are ~10x cheaper and almost always sufficient for a coding agent. If you genuinely need full text, always cap it with `contents.text.maxCharacters`.
- `outputSchema` — enrichment and structured-data pipelines. Skip it here; adding a schema means debugging JSON schema validity on top of everything else.
- `maxAgeHours` — controls *cache freshness*, not result recency. Omit by default. `0` only for genuinely real-time data; `-1` for static historical content where speed matters. This is not a date filter — `--since` is.
- `category` (`company`, `people`, `publication`, `news`, `personal site`, `financial report`), `userLocation`, `stream`, `systemPrompt`, `additionalQueries`, `moderation`.

## Footguns

Each of these otherwise costs a debugging round-trip:

- **`tokensNum` exists only on `/context`.** It is deprecated on `/search` and does nothing there. To limit `/search` content length use `contents.text.maxCharacters`. An agent reading both endpoint docs will absolutely try it in the wrong place.
- **`text`, `summary`, and `highlights` nest under `contents` on `/search`, but are top-level on `/contents`.** Same field names, different position, two endpoints.
- **`excludeDomains`, `startPublishedDate`, and `endPublishedDate` are all rejected with HTTP 400 when `category` is `company` or `people`.**
- **camelCase everywhere.** Raw JSON and the JS SDK use `maxCharacters` / `maxAgeHours`; only the Python SDK uses snake_case. The script is cURL, so camelCase — including inside nested objects.
- The response field for the resolved search type is **`resolvedSearchType`**, not `searchType`. `searchType` is absent, so a `jq` fallback on it silently yields null.

### Removed / deprecated — do not use

| Parameter | Instead |
|---|---|
| `useAutoprompt` | nothing, it's a no-op |
| `numSentences` | `highlights: true` |
| `highlightsPerUrl` | `highlights: true` |
| `livecrawl: "always"` | `contents.maxAgeHours: 0` |
| `includeUrls` / `excludeUrls` | `includeDomains` / `excludeDomains` (the URL forms don't exist) |

## Auth

The API key *is* the credential. Both header forms take the same value with the
same permissions:

```
x-api-key: $EXA_API_KEY
Authorization: Bearer $EXA_API_KEY
```

There is no token-minting endpoint and no OAuth exchange for the REST API
(OAuth exists only for the hosted MCP server's browser sign-in — a different
path). The script standardizes on `x-api-key`, verified working against both
`/search` and `/context`; the published docs show the `Bearer` form. Mixing the
two across endpoints is how you end up debugging a 401 that isn't one.

## HTTP status codes

| Status | Meaning |
|---|---|
| 400 | Bad request — invalid parameters (check the footguns above) |
| 401 | Invalid or missing API key |
| 422 | Validation error |
| 429 | Rate limited |
| 500 | Exa-side error |
