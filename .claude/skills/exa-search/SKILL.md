---
name: exa-search
description: >-
  Search the web and open-source code for library usage, API syntax, and
  documentation via Exa. Use this whenever verifying an API signature, looking
  up how a library is used, checking a config file format, or resolving an error
  from a third-party dependency -- including when you think you already know the
  answer, since library APIs drift.

  Also use for questions documentation cannot answer: release timing, breaking
  changes, "is X still maintained", licensing, security advisories, and
  ecosystem comparisons.
---

# Exa Search

Two endpoints behind one script. All HTTP lives in `scripts/exa.sh` — never call
`api.exa.ai` directly, and never paste the API key into a command.

```bash
scripts/exa.sh context "<query>" [--tokens N|dynamic]
scripts/exa.sh search  "<query>" [--type auto|instant|fast|deep-lite|deep|deep-reasoning]
                                 [--results N] [--domains a.com,b.com]
                                 [--exclude c.com] [--since YYYY-MM-DD] [--chars N]
```

The key is read from `~/.env`. If the script reports `EXA_API_KEY not set`, tell
the user to add it rather than working around it.

## Route to `/context` first

`/context` is the default for anything code-shaped: library and framework usage,
API syntax, config file shape, build tooling setup, error messages from a known
library, "how do I do X with Y". Exa does retrieval, extraction, reranking, and
concatenation server-side and returns one budget-capped string.

Start at the default `--tokens 5000`. Retry once at `10000` only if the first
response clearly doesn't cover the question. Use `--tokens dynamic` for
open-ended queries where you can't guess the budget, and a smaller value like
`1000` for a single-fact lookup.

```bash
scripts/exa.sh context "expose a Rust struct to Node via napi-rs threadsafe function"
```

## Fall through to `/search` only when one of these holds

1. `/context` returned an empty response, or never mentioned the library you asked about.
2. The query isn't code-shaped — release announcements, maintenance status, licensing, pricing, security advisories, ecosystem comparisons, migration timing.
3. You need **recency**. `/context` has no date filter; a confidently-formatted snippet from three years ago looks identical to a current one. `/search --since` is the only way to bound this.
4. You need **provenance control** — restricting to official docs, or excluding a source you know is wrong.
5. You need to **follow up** on a specific page. `/context` returns bare inline URLs in prose; `/search` returns structured results with titles and URLs you can fetch.

**Narrate the fallback as an explicit decision**, not a silent retry:

> Context returned nothing on the napi-rs threadsafe function API, falling back
> to search restricted to docs.rs.

**Fall through at most once.** If `/search` also comes back thin, report that and
stop. Do not escalate to `--type deep-reasoning` and burn 40 seconds on a query
that has already failed twice.

## Search defaults

The script already defaults to `--type auto`, `--results 10`, and highlights
capped at 600 characters per result. That is the right shape for nearly every
coding question — take it unless you can state why not.

Escalating `--type` past `auto` requires a stated reason. `deep` (4-15s) is for
synthesis across sources; `deep-reasoning` (12-40s) is for conflicting sources
and multi-step research. Over-escalating on a trivial lookup is the most common
failure mode here — "what's the default port for the Vite dev server" is an
`instant`/`context` question, not a `deep` one.

**Empty results?** Remove filters first, then simplify the query. Adding *more*
constraints to a query that returned nothing is the most common wrong move.

## Parameter reference

Read `references/search-tuning.md` when tuning `/search` filters, choosing a
`type`, or debugging a 400 — it carries the full parameter tables and the API
footguns (which parameters are deprecated, which are endpoint-specific, and
which category/filter combinations return 400).

Do not read it for a routine `/context` lookup.
