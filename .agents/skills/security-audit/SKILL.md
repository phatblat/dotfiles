---
name: security-audit
description: Run an infrastructure-first security audit of a repository - secrets archaeology, dependency supply chain, CI/CD pipeline, LLM/AI attack surface, agent skill supply chain, OWASP Top 10, STRIDE threat model, and data classification - with a confidence gate and a pre-emit verification gate that suppress speculative findings. Use when asked for a security audit, threat model, pentest-style review, OWASP pass, or a pre-release security check. Not for reviewing a single diff - use review-changes or requesting-code-review for that.
---

# Security Audit

A repository security audit that reports **exploitable findings, not absent best
practices**. The discipline that makes it useful is the filtering: a confidence
gate, twenty-two hard exclusions, and a rule that no finding ships unless you can
quote the line that motivates it.

Derived from gstack's `/cso` skill (MIT).

## Modes

| Mode | Gate | Use |
|---|---|---|
| **Daily** (default) | 8/10 confidence | Zero noise. Only what you're sure about. |
| **Comprehensive** | 2/10 confidence | Monthly deep scan. Filter true noise only; mark everything below 8 as `TENTATIVE`. |

Diff mode: scope every phase to `<base>..HEAD` instead of full history.

## Phase 0 — Stack detection

Identify languages, frameworks, package managers, container/IaC tooling, and CI
provider. Scope every later grep to the detected stacks. Record what you found;
phases that don't apply are skipped, not failed.

## Phase 1 — Attack surface census

Enumerate every trust boundary: inbound routes, webhook endpoints, auth entry
points, third-party integrations, background jobs consuming external data, and
anything reading from the network or the filesystem at privilege.

## Phase 2 — Secrets archaeology

Git history for leaked credentials, tracked `.env` files, CI configs with inline
secrets.

```bash
git log -p --all -S "AKIA" --diff-filter=A -- "*.env" "*.yml" "*.yaml" "*.json" "*.toml"
git log -p --all -G "ghp_|gho_|github_pat_"
git log -p --all -G "xoxb-|xoxp-|xapp-"
git log -p --all -G "password|secret|token|api_key" -- "*.env" "*.yml" "*.json" "*.conf"
git ls-files '*.env' '.env.*' | grep -v '.example\|.sample\|.template'
```

High-signal prefixes: `AKIA`, `ghp_`, `sk-ant-`, `sk_live_`, `xoxb-`,
`-----BEGIN ... PRIVATE KEY-----`.

**Severity.** CRITICAL for live secret patterns in history. HIGH for `.env`
tracked, CI configs with inline credentials. MEDIUM for suspicious
`.env.example` values.

**FP rules.** Placeholders (`your_`, `changeme`, `TODO`) excluded. Test fixtures
excluded unless the same value appears in non-test code. Rotated secrets are
still findings — they were exposed.

## Phase 3 — Dependency supply chain

Beyond `npm audit`. Run whichever audit tool the detected package manager
provides; a missing tool is "SKIPPED — not installed", not a finding.

- Install scripts (`preinstall`/`postinstall`/`install`) in **production** deps
- Lockfile exists **and** is tracked by git
- Known CVEs in direct dependencies

**Severity.** CRITICAL for high/critical CVEs in direct deps. HIGH for install
scripts in prod deps, missing lockfile. MEDIUM for abandoned packages, lockfile
untracked.

**FP rules.** devDependency CVEs cap at MEDIUM. `node-gyp`/`cmake` install
scripts are expected. Missing lockfile in a *library* repo is not a finding.

## Phase 4 — CI/CD pipeline security

Who can modify workflows, and what secrets can they reach?

- Unpinned third-party actions (no SHA pin)
- `pull_request_target` **with** checkout of PR code
- Script injection via `${{ github.event.* }}` inside `run:`
- Secrets exposed as env vars
- CODEOWNERS protection on workflow files

**Severity.** CRITICAL for `pull_request_target` + PR checkout, script
injection. HIGH for unpinned third-party actions, unmasked secrets in `env:`.
MEDIUM for missing CODEOWNERS.

**FP rules.** First-party `actions/*` unpinned is MEDIUM. `pull_request_target`
*without* PR ref checkout is safe. Secrets in `with:` are runtime-handled.

## Phase 5 — Infrastructure shadow surface

- Dockerfiles: missing `USER`, secrets as `ARG`, `.env` copied into images
- Config files with prod DB URLs (`postgres://`, `mysql://`, `mongodb://`,
  `redis://`), excluding localhost/example.com
- Terraform: `"*"` in IAM actions/resources, secrets in `.tf`/`.tfvars`
- K8s: privileged containers, `hostNetwork`, `hostPID`

**FP rules.** `docker-compose.yml` for local dev on localhost is not a finding.
Terraform `"*"` in read-only `data` sources excluded. Manifests under
`test/`/`dev/`/`local/` with localhost networking excluded.

## Phase 6 — Webhook and integration audit

Find inbound endpoints that accept anything. For every webhook/callback route,
check whether signature verification exists **anywhere** in the middleware chain
(`hmac`, `x-hub-signature`, `stripe-signature`, `svix`, `verify`, `digest`).

Also: TLS verification disabled (`InsecureSkipVerify`, `VERIFY_NONE`,
`NODE_TLS_REJECT_UNAUTHORIZED=0`), overly broad OAuth scopes.

**Trace code only. Never send live requests to a webhook endpoint.**

**FP rules.** TLS disabled in test code excluded. Internal service-to-service
webhooks on private networks cap at MEDIUM. Endpoints behind a gateway that
verifies upstream are not findings — but that requires evidence.

## Phase 7 — LLM and AI security

A distinct attack class. Search for:

- User input interpolated into **system prompts** or **tool schemas**
- LLM output rendered unsanitized (`dangerouslySetInnerHTML`, `v-html`,
  `innerHTML`, `.html()`, `raw()`)
- Tool/function calling without validation before execution
- AI API keys hardcoded rather than read from env
- `eval()`/`exec()`/`new Function()` over model output
- RAG poisoning: can retrieved documents steer behavior?
- Cost amplification: can a user trigger unbounded model calls?

**FP rule.** User content in the *user-message position* of a conversation is not
prompt injection. Only flag when it reaches a system prompt, tool schema, or
function-calling context.

## Phase 8 — Agent skill supply chain

Installed agent skills are executable prompt code, not documentation. Scan
repo-local skill files for:

- Network exfiltration: `curl`, `wget`, `fetch` to suspicious targets
- Credential access: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `process.env`
- Prompt injection: `IGNORE PREVIOUS`, `system override`, `disregard`,
  `forget your instructions`

Scanning **globally** installed skills and hooks reads files outside the repo —
ask before doing it.

**FP rule.** `curl` for a documented download or health check needs context. Flag
when the target URL is suspicious or the command carries credential variables.

## Phase 9 — OWASP Top 10

| | Focus |
|---|---|
| A01 Broken Access Control | Missing auth on routes; IDOR via `params[:id]`; horizontal/vertical escalation |
| A02 Cryptographic Failures | MD5/SHA1/DES/ECB; data encrypted at rest and in transit; key management |
| A03 Injection | SQL string interpolation; `system()`/`exec()`/`popen`; template injection; see Phase 7 for prompts |
| A04 Insecure Design | Rate limits on auth; account lockout; server-side business-logic validation |
| A05 Security Misconfiguration | Wildcard CORS in prod; CSP headers; debug mode / verbose errors |
| A06 Vulnerable Components | See Phase 3 |
| A07 AuthN Failures | Session lifecycle; password policy; MFA for admin; JWT expiry and refresh rotation |
| A08 Integrity Failures | See Phase 4; deserialization input validation |
| A09 Logging Failures | Auth events, authz failures, admin actions audit-trailed; logs tamper-protected |
| A10 SSRF | URL built from user input; internal service reachability; outbound allowlist |

## Phase 10 — STRIDE threat model

For each major component from Phase 1:

```
COMPONENT: [Name]
  Spoofing:               Can an attacker impersonate a user/service?
  Tampering:              Can data be modified in transit/at rest?
  Repudiation:            Can actions be denied? Is there an audit trail?
  Information Disclosure: Can sensitive data leak?
  Denial of Service:      Can the component be overwhelmed?
  Elevation of Privilege: Can a user gain unauthorized access?
```

## Phase 11 — Data classification

```
RESTRICTED   (breach = legal liability): credentials, payment data, PII
CONFIDENTIAL (breach = business damage): API keys, trade secrets, behavior data
INTERNAL     (breach = embarrassment):   system logs, configuration
PUBLIC:                                  docs, marketing, public APIs
```

For each: where stored, how protected, retention and rotation policy.

## Phase 12 — False-positive filtering

Every candidate runs this filter before it can become a finding.

### Hard exclusions — discard automatically

1. DoS, resource exhaustion, rate limiting. **Exception:** LLM cost amplification
   from Phase 7 is financial risk, not DoS.
2. Secrets on disk that are otherwise secured (encrypted, permissioned).
3. Memory/CPU/file-descriptor exhaustion.
4. Input validation on non-security-critical fields without proven impact.
5. CI workflow issues not triggerable by untrusted input. **Exception:** never
   discard Phase 4 findings — that phase exists to surface them.
6. Missing hardening. Report concrete vulnerabilities, not absent best practices.
   **Exception:** unpinned third-party actions and missing CODEOWNERS are
   concrete risks.
7. Race conditions or timing attacks without a concrete exploit path.
8. CVEs in outdated libraries — Phase 3 handles these in aggregate.
9. Memory safety in memory-safe languages (Rust, Go, Java, C#).
10. Files that are only tests or fixtures and are not imported by non-test code.
11. Log spoofing. Unsanitized input in logs is not a vulnerability.
12. SSRF where the attacker controls only the path, not host or protocol.
13. User content in the user-message position of an AI conversation.
14. Regex complexity in code that never processes untrusted input.
15. Findings in `*.md` documentation. **Exception:** `SKILL.md` files are
    executable prompt code — Phase 8 findings are never excluded here.
16. Missing audit logs. Absence of logging is not a vulnerability.
17. Insecure randomness outside security contexts (UI element IDs).
18. Secrets committed and removed within the same initial-setup PR.
19. Dependency CVEs with CVSS < 4.0 and no known exploit.
20. `Dockerfile.dev` / `Dockerfile.local` issues, unless referenced by prod deploy config.
21. Findings on archived or disabled workflows.
22. Anything whose only impact is theoretical.

### Precedents

1. Logging secrets in plaintext is a vulnerability. Logging URLs is safe.
2. UUIDs are unguessable — don't flag missing UUID validation.
3. Environment variables and CLI flags are trusted input.
4. React and Angular are XSS-safe by default. Flag only the escape hatches.
5. Client-side JS doesn't need auth — that's the server's job.
6. Shell command injection needs a concrete untrusted input path.
7. Subtle web vulnerabilities only at very high confidence with a concrete exploit.
8. Notebooks: only if untrusted input can trigger it.
9. Logging non-PII data is not a vulnerability.
10. Untracked lockfile is a finding for apps, not libraries.
11. `pull_request_target` without PR ref checkout is safe.
12. Root containers in local `docker-compose.yml` are fine; in prod Dockerfiles/K8s they are findings.

### Active verification

For each surviving finding, prove it where safe — **by reading code, never by
sending traffic**:

| Finding type | How to verify |
|---|---|
| Secrets | Is the pattern a real key format (length, prefix)? Never test against live APIs. |
| Webhooks | Trace the middleware chain for signature verification. No HTTP requests. |
| SSRF | Trace whether user-controlled URL construction reaches an internal service. |
| CI/CD | Parse the workflow YAML; confirm `pull_request_target` actually checks out PR code. |
| Dependencies | Is the vulnerable function directly imported/called? If not, mark UNVERIFIED and say it may still be reachable via framework internals. |
| LLM | Trace whether user input actually reaches system-prompt construction. |

Mark each: `VERIFIED` · `UNVERIFIED` (pattern match only) · `TENTATIVE`
(comprehensive mode, below 8/10).

**Variant analysis.** One verified SSRF means there may be five more. For each
VERIFIED finding, extract the pattern, search the whole codebase, and report
variants linked to the original.

**Independent verification.** Spawn a verifier subagent per candidate with the
file:line and the FP rules **only** — never your reasoning, which anchors it.
Ask: "Read the code at this location. Is there a vulnerability? Score 1-10.
Below 8, explain why it isn't real." Discard what fails the gate. If subagents
are unavailable, re-read with a skeptic's eye and note "self-verified".

## Phase 13 — Pre-emit verification gate

This is the rule that kills the largest false-positive class. Before any finding
reaches the report:

1. **Quote the specific line(s) that motivate it** — file:line plus verbatim
   text. "Field X doesn't exist on model Y" requires quoting the body of Y.
   "`dict.get()` may return None" requires quoting the dict initialization.
   "Race between A and B" requires quoting both.
2. **If you cannot quote it, the finding is unverified.** Force confidence to
   4-5, suppress it from the main report, keep it in an appendix. Do not invent
   confidence 7+ to route around this gate.

**Framework-meta nudge.** When a symbol is generated by a metaclass, descriptor,
ORM `Meta`, migration, or decorator (Django `Meta`, Rails `has_many`, SQLAlchemy
`relationship`, TypeORM decorators, Prisma client), quote the meta-construct
instead of expecting a literal name in the class body. The bar is "I read the
source that creates this symbol", not "I grepped and found nothing."

## Confidence calibration

| Score | Meaning | Display |
|---|---|---|
| 9-10 | Verified against specific code; concrete exploit | Show |
| 7-8 | High-confidence pattern match | Show |
| 5-6 | Moderate; could be a false positive | Show with "verify this is actually an issue" |
| 3-4 | Suspicious but likely fine | Appendix only |
| 1-2 | Speculation | Only if severity would be P0 |

## Report

Every finding MUST carry a concrete exploit scenario — a step-by-step attack
path. "This pattern is insecure" is not a finding.

```
SECURITY FINDINGS
═════════════════
#   Sev    Conf   Status      Category         Finding                          Phase   File:Line
──  ────   ────   ──────      ────────         ───────                          ─────   ─────────
1   CRIT   9/10   VERIFIED    Secrets          AWS key in git history           P2      .env:3
2   CRIT   9/10   VERIFIED    CI/CD            pull_request_target + checkout   P4      .github/ci.yml:12
3   HIGH   8/10   VERIFIED    Supply Chain     postinstall in prod dep          P3      package.json:41
4   HIGH   9/10   UNVERIFIED  Integrations     Webhook w/o signature verify     P6      api/webhooks.ts:24
```

Then, per finding:

```
## Finding N: [Title] — [file:line]

* Severity:    CRITICAL | HIGH | MEDIUM
* Confidence:  N/10
* Status:      VERIFIED | UNVERIFIED | TENTATIVE
* Phase:       N — [name]
* Evidence:    <verbatim quoted line(s) that motivate this>
* Exploit:     <step-by-step attack path>
* Fix:         <specific remediation with example>
```

Close with counts by severity and an explicit statement of which phases were
skipped and why.
