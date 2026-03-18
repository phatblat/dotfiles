---
name: security-audit
description: |-
  Proactive security audit: OWASP top 10, dependency vulnerabilities, secrets detection,
  input validation, auth patterns, and secure defaults.
  MUST BE USED when user mentions: "security", "vulnerability", "audit", "OWASP", "CVE",
  "security review", "pentest", "injection", "XSS", "CSRF", "authentication",
  "authorization", "secrets", "hardcoded password", "secure", "npm audit", "pip-audit",
  "check security", "is this secure", "security risk", "data leak", "SQL injection",
  "command injection", "path traversal", "SSRF", "RCE", "privilege escalation",
  "supply chain", "dependency scan", "snyk", "trivy", "semgrep", "bandit".
  Scans code for vulnerabilities, checks dependencies, verifies auth patterns.
  NOT for explaining security concepts (use pedagogical-explain),
  or general code review (use code-review).
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - WebSearch
  - WebFetch
  - Agent
---

# Security Audit

## Overview

Systematic security review covering OWASP Top 10, dependency vulnerabilities, secrets, and secure patterns.

## Process

```
Phase 1: SCAN      -> Automated scans (deps, secrets, patterns)
Phase 2: ANALYZE   -> Manual review of high-risk areas
Phase 3: CLASSIFY  -> Rate findings by severity
Phase 4: RECOMMEND -> Propose fixes with priority
```

## Phase 1: Automated Scans

### Dependency Vulnerabilities

```bash
# JavaScript/TypeScript
npm audit

# Python
uv run pip-audit

# Rust
cargo audit
```

### Secrets Detection

Search for hardcoded secrets using Grep:

```
Patterns to search for:
- API keys: long alphanumeric strings in config files
- Credentials: password/token/secret assignments with literal values
- Cloud provider keys: AWS access key patterns (starts with AKIA)
- Private key headers: PEM format key blocks
- Connection strings: database URIs containing embedded credentials
- .env files: verify .env is listed in .gitignore
```

Use Grep tool to search for these patterns across the codebase. Focus on:
- Configuration files (*.config.*, *.yml, *.yaml, *.json, *.toml)
- Source code with string assignments to variables named key, secret, token, password
- Environment variable files that should NOT be committed

### Dangerous Code Patterns

Search with Grep for:

| Pattern | Risk | What to Search |
|---------|------|----------------|
| eval/exec | Code injection | `eval(`, `exec(`, `Function(` |
| SQL concatenation | SQL injection | String concatenation in SQL queries |
| Shell execution | Command injection | `subprocess.call`, `os.system`, `child_process.exec` |
| Unsafe HTML | XSS | `dangerouslySetInnerHTML`, `innerHTML =`, `v-html` |
| Unsafe deserialization | RCE | `pickle.load`, `yaml.load` without SafeLoader |
| Open redirect | Phishing | Redirects using user-controlled input |
| Path traversal | File access | `../` patterns in user-controlled paths |

## Phase 2: Manual Review

### OWASP Top 10 Checklist

| # | Vulnerability | What to Check |
|---|--------------|---------------|
| A01 | Broken Access Control | Auth middleware on all routes, RBAC, CORS |
| A02 | Cryptographic Failures | TLS, proper password hashing (bcrypt/argon2), no weak hashing for passwords |
| A03 | Injection | SQL parameterized queries, XSS escaping, command injection |
| A04 | Insecure Design | Business logic flaws, missing rate limiting |
| A05 | Security Misconfiguration | Default credentials, verbose errors in prod, CORS wildcard |
| A06 | Vulnerable Components | Outdated deps, known CVEs |
| A07 | Auth Failures | Session management, brute force protection, MFA |
| A08 | Data Integrity | Unsigned updates, CI/CD pipeline security |
| A09 | Logging Failures | Missing audit logs, PII in logs |
| A10 | SSRF | Unvalidated URLs, internal network access |

### Authentication Review

```
Check:
- Password storage    -> bcrypt/argon2 (NOT md5/sha1/sha256)
- Session management  -> Secure, HttpOnly, SameSite cookies
- JWT                 -> Algorithm validation, expiry, refresh tokens
- Rate limiting       -> Login attempts, API endpoints
- CORS                -> Not wildcard for authenticated routes
- CSRF                -> Tokens on state-changing operations
```

### Input Validation Review

```
Check:
- User inputs         -> Validated and sanitized at entry
- File uploads        -> Type validation, size limits, no path traversal
- API parameters      -> Schema validation (zod, pydantic, joi)
- Database queries    -> Parameterized, no string concatenation
- Redirects           -> Whitelist-only destinations
```

## Phase 3: Classify Findings

| Severity | Criteria | Action |
|----------|----------|--------|
| CRITICAL | Remote code execution, auth bypass, data leak | Fix immediately |
| HIGH | XSS, SQL injection, broken access control | Fix before deploy |
| MEDIUM | Missing headers, weak validation, info disclosure | Fix soon |
| LOW | Best practice violations, minor misconfigs | Plan fix |
| INFO | Suggestions, hardening opportunities | Optional |

## Phase 4: Report

```markdown
## Security Audit Report

**Scope**: [files/directories audited]
**Date**: [date]

### Executive Summary
[2-3 sentences: overall posture, critical findings count]

### Findings

#### CRITICAL
| # | Finding | File:Line | Description | Fix |
|---|---------|-----------|-------------|-----|
| 1 | [type] | path:42 | [detail] | [remediation] |

#### HIGH
| # | Finding | File:Line | Description | Fix |
|---|---------|-----------|-------------|-----|

#### MEDIUM
[...]

#### LOW
[...]

### Dependency Audit
| Package | Version | Vulnerability | Severity | Fix Version |
|---------|---------|---------------|----------|-------------|

### Positive Security Practices Found
- [What's already well done]

### Recommendations (Priority Order)
1. **[Action]** -- Addresses [finding], estimated effort: [S/M/L]
2. **[Action]** -- Addresses [finding], estimated effort: [S/M/L]

### Confidence: [LEVEL]
[Based on scope coverage and tool results]
```

## Rules

- Scan ALL files, not just the ones mentioned
- Never ignore a finding because it seems unlikely
- Provide concrete fix code, not just descriptions
- Check .gitignore for excluded sensitive files
- Verify secrets are in environment variables, not code
- Flag false positives clearly to avoid noise
- Don't create security vulnerabilities while demonstrating fixes
