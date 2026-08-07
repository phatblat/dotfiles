---
name: ramp-x402-pay
area: Agentic Commerce
supported_surfaces: [cli, mcp]
description: "Pay an x402 (HTTP 402) payment challenge from a merchant using the business's Ramp agentic Solana USDC wallet, then attach the payment and get the resource. Use when asked to pay for an x402 API/resource, 'pay with x402', buy an Exa search, create an AgentMail inbox, pay a paid API that returns 402, or complete/test an x402 payment. Requires the ramp CLI authenticated with the x402:write scope and a provisioned agentic Solana wallet."
user-invocable: true
---

# x402 Pay

Pay an HTTP 402 payment challenge with the business's Ramp **agentic Solana USDC wallet**. The `ramp` CLI signs the payment; you attach the returned header to the original request and the merchant settles it on Solana.

## Prerequisites

- `ramp` CLI installed and authenticated (`ramp auth login`). Tokens expire (~7 days) — check `ramp auth status`.
- The token must carry the **`x402:write`** scope. If missing, `ramp auth login` again to request it.
- The business must have a provisioned **AGENTIC (non-custodial) Solana wallet funded with USDC**. There is no auto-funding — a low balance means payments fail.

## The flow (four steps)

The x402 challenge and settlement receipt travel in **response headers** (x402 v2 HTTP transport), not the response body. Read the challenge from the base64-encoded `PAYMENT-REQUIRED` response header and the settlement receipt from the `PAYMENT-RESPONSE` response header. The body is a fallback only.

1. **Get the challenge.** Send the merchant's request with **no payment** → HTTP `402`. **Decode the `PAYMENT-REQUIRED` response header (base64 → JSON) as the primary source of the challenge** — it holds the `accepts` array (plus, on v2 merchants, `resource` and `extensions`). **Only if that header is absent, fall back to parsing the JSON body.** A 402 whose body is just an error is normal and expected — do not treat it as a dead end; the real challenge is in the header.
   ```bash
   # header value is base64-encoded JSON; e.g.
   printf '%s' "$payment_required_header" | base64 -d | python3 -m json.tool
   ```
2. **Pick the Solana accept** and confirm it's the *supported dialect* (see [Supported vs unsupported](#supported-vs-unsupported-challenges) — this is the #1 thing to check).
3. **Confirm the final terms, then sign.** The 402 challenge is **merchant-controlled** — amount, recipient, network, and asset all come from the merchant, and signing authorizes a real USDC transfer from the business wallet. **Before calling `ramp general pay`, surface the exact terms and get explicit approval** (from the user, or your caller's spend policy): the merchant / `resource` URL, the **exact amount + asset** (e.g. `7000` = 0.007 USDC), the **exact recipient wallet address** (the chosen accept's `payTo` — show the full address, since that is where the funds actually go), the **network**, and the **source wallet/business**. Never auto-approve a merchant-supplied amount or recipient, and never sign a challenge whose terms you haven't confirmed. Then sign — the tool returns a ready-to-send header:
   ```bash
   ramp general pay --json '{"accepted": <the chosen accept, verbatim>,
                             "resource": <the challenge resource, verbatim>,
                             "extensions": <the challenge extensions, verbatim or omit>,
                             "decimals": 6,
                             "rationale": "why you are paying"}'
   ```
   Returns `payment_header_name`, `payment_header_value` (attach these), plus `signed_transaction` and `x402_authorization_id` (debug only).
4. **Attach and resend.** Put `payment_header_value` under `payment_header_name` on the **same original request** and send again → `200` + the resource. Confirm settlement by decoding the **`PAYMENT-RESPONSE` response header** the same way as the challenge (base64 → JSON: `success`, `transaction`, `network`, `payer`).

Do the whole loop promptly: the signed Solana transaction is blockhash-bound (~60–90s) and the accept has a `maxTimeoutSeconds`. Fetch → sign → submit back-to-back.

## Hard rules / gotchas

These each cost real debugging time — respect them.

- **The challenge lives in the `PAYMENT-REQUIRED` response header, not the body.** A 402 with only an error body is normal — decode the base64 `PAYMENT-REQUIRED` header (→ JSON) to get `accepts` / `resource` / `extensions`, and only fall back to the body if that header is absent. Many spec-strict merchants (CoinGecko, apitoll, ip402, ottoai) send the challenge *only* in the header; reading the body alone silently misses them. The same goes for settlement: read it from the base64 `PAYMENT-RESPONSE` response header.
- **Confirm terms before signing — the challenge is merchant-controlled.** Amount, recipient, network, and asset all come from the merchant's 402, and signing spends real USDC from the business wallet. Get explicit approval of the merchant, exact amount + asset, **exact recipient address (`payTo`)**, network, and source wallet/business before calling `ramp general pay`. Server-side per-transaction spend caps are not enforced yet, so this approval gate is the primary control against an unintended payment.
- **The invocation is `ramp general pay`**, not `ramp x402`. The tool folds into the `general` command group.
- **The tool SIGNS but does NOT SUBMIT.** It never calls the merchant — you attach the header and resend yourself. Signing alone moves no money, so a failed submit costs nothing and is safe to retry.
- **Header name matters: `PAYMENT-SIGNATURE` (x402 v2), not `X-PAYMENT` (v1).** The tool returns the correct name in `payment_header_name` — use it, don't hardcode. Lenient merchants accept `X-PAYMENT`; strict ones (AgentMail) **silently re-issue a 402** on the wrong header, which looks like "no payment attached."
- **Pass `accepted` / `resource` / `extensions` verbatim** from the challenge via `--json` (they're objects — they can't go as flags). The tool builds the v2 PaymentPayload envelope for you; **do not hand-assemble it.** `accepted` must be the *entire* chosen `accepts[]` entry as received.
- **`amount` is atomic units; pass `decimals: 6` for USDC** (7000 = 0.007 USDC, 2000000 = 2 USDC). The tool doesn't resolve decimals from the mint yet.
- **Amount-0 (free) endpoints still require the full handshake** — you still sign a 0-value transfer and attach the header (e.g. AgentMail's read endpoint).
- **Verify settlement** by decoding the `PAYMENT-RESPONSE` **response header** (base64 JSON: `success`, `transaction`, `network`, `payer`). To be certain, confirm on-chain: `getTransaction` against a Solana RPC and check the USDC balance delta.

## Supported vs unsupported challenges

The tool supports **one** x402 Solana dialect — the **v2 facilitator-sponsored** scheme. Not every merchant that says "Solana" uses it. Before signing, check the Solana accept:

**Supported (proceed):**
- `network` is the CAIP-2 mainnet id `solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp`
- the amount is in an `amount` field
- `extra.feePayer` is present (the facilitator sponsors the transaction fee)

**Unsupported today (stop, tell the user):**
- `network` is the bare alias `"solana"`, or
- the amount is in `maxAmountRequired`, or
- there is **no** `extra.feePayer` (a "self-funded" dialect where the payer sponsors its own fee)

The tool will hard-reject unsupported accepts (e.g. `invalid enum value 'solana' at 'accepted.network'`). This is a known gap, not a bug in your inputs — the signing path assumes a facilitator fee payer.

## Merchant memory

Verified request shapes so you skip rediscovery. Amounts are the observed price, not a cap.

### Exa — search  (v2, supported · verified 2026-07-14)
```yaml
challenge:  POST https://api.exa.ai/search   body {"query": "...", "numResults": 3}
solana_accept: {scheme: exact, network: "solana:5eykt4...", amount: "7000" (~0.007 USDC),
                asset: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v (USDC), extra.feePayer present}
extensions: [bazaar, agentkit]   # agentkit is a "prove you're human" free-trial handshake;
                                 # echoing it back is harmless when paying directly — do NOT try to satisfy it.
submit:     resend the same POST with the PAYMENT-SIGNATURE header → 200 + results + PAYMENT-RESPONSE
```

### AgentMail — inbox as agent identity  (v2, supported · verified 2026-07-14)
```yaml
base_host:  https://x402.api.agentmail.to
create:     POST /v0/inboxes                         body {}                      ~2000000 (2 USDC)
read:       GET  /v0/inboxes/{inbox}/messages        (no body)                    amount 0 (FREE, still handshake)
send:       POST /v0/inboxes/{inbox}/messages/send   body {to, subject, text}     ~10000 (0.01 USDC)
extensions: [bazaar]
note:       full identity loop works — create inbox → use its address to sign up for a service
            (e.g. Telnyx magic-link) → the verification email lands in the inbox → read it via the free read.
            The plain api.agentmail.to host needs an API key (401); the x402 host is key-free per-call.
```

### Browserbase — session  (v1 self-funded · UNSUPPORTED · checked 2026-07-14)
```yaml
challenge:  POST https://x402.browserbase.com/browser/session/create   body {"estimatedMinutes": 30}
status:     NOT payable with this tool today. x402Version 1; Solana accept uses network "solana"
            (not CAIP-2), maxAmountRequired (not amount), NO extra.feePayer (payer self-funds),
            X-PAYMENT header. Base (EVM) accept is also offered but the tool is Solana-only.
action:     tell the user Browserbase isn't supported yet and why (self-funded dialect); don't retry.
```

Merchant directories (e.g. **agentic.market**) list more x402 services, but most are **Base/EVM-only** and unusable here — always filter for a *supported* Solana accept per the rules above.

## When it fails

`ramp general pay` returns an HTTP status and error message in the CLI output — start there. Failure modes, by what you can do about them:

- **Validation errors (400)** — usually a wrong dialect (unsupported network, missing `feePayer`) or reshaped payload keys. Re-check the accept against [Supported vs unsupported](#supported-vs-unsupported-challenges) and pass `accepted`/`resource`/`extensions` verbatim (camelCased, exactly as received).
- **Auth errors (401/403)** — run `ramp auth status` and re-login if needed. If auth is fine and the call is still rejected, the business may not have x402 payments enabled — the user should contact Ramp support to enable it.
- **Signing errors (5xx)** — not caused by your input, and signing moves no money. Retry once; if it persists, stop and have the user contact Ramp support with the timestamp and the CLI error output.
- **Merchant rejects the payment after the tool returned a header (a fresh 402 on resend)** — merchant-side, distinct from a tool error (e.g. compute-unit limit or a stricter echo requirement). The signed-but-unsubmitted payment cost nothing; report the merchant's error to the user rather than retrying blindly.
