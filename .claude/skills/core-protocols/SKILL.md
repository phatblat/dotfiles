---
name: core-protocols
description: |-
  Debug errors systematically by searching first, then analyzing, then proposing verified solutions.
  MUST BE USED when user reports: "error", "bug", "doesn't work", "fails", "crash", stack traces,
  exception messages, or any troubleshooting scenario.
  Triggers: "TypeError", "ImportError", "undefined is not a function", "segfault", "panic",
  "broken", "not working", "unexpected behavior", "regression", "failing", "exception",
  "traceback", "stack trace", "debug this", "why does this fail", "help me fix".
  Also enforces confidence levels and output templates. Prevents guessing solutions without research.
allowed-tools:
  - WebSearch
  - WebFetch
  - mcp__context7__resolve-library-id
  - mcp__context7__get-library-docs
  - mcp__fetch__fetch
  - Read
  - Grep
  - Glob
---

# Core Protocols

## 1. Debugging Protocol

### Trigger Conditions

Activate when:
- User reports an error or bug
- Code doesn't work as expected
- Build/test failures occur
- Stack traces or error messages appear

### MANDATORY Sequence

**NEVER propose solutions before completing Steps 1-2.**

#### Step 1: SEARCH FIRST

```
1. Extract EXACT error message
2. WebSearch: "[error message] [language/framework] [version]"
3. Context7 if library-related:
   - mcp__context7__resolve-library-id(libraryName)
   - mcp__context7__get-library-docs(id, topic: "error")
4. Look for GitHub issues / StackOverflow
```

#### Step 2: ANALYZE

```
1. Identify ROOT CAUSE (not symptoms)
2. Check version compatibility
3. Isolate the problem
4. Check changelogs for breaking changes
```

#### Step 3: VERIFIED SOLUTION

```
1. Cite SOURCE of solution
2. State CONFIDENCE level
3. Propose ALTERNATIVES if uncertain
4. Include VALIDATION command
```

### Error Type Quick Reference

| Error Type | First Action |
|------------|--------------|
| Library/API error | Context7 lookup |
| Runtime error | WebSearch exact message |
| Build error | Check versions, config |
| Type error | Read type definitions |
| Import error | Check package installation |

---

## 2. Confidence Assessment

### Levels

| Level | Criteria | Action |
|-------|----------|--------|
| **HIGH** | Verified via tool, 2+ sources | State source |
| **MEDIUM** | Single source, partial verification | Add caveat |
| **LOW** | Memory only, no verification | Warn explicitly |
| **UNKNOWN** | Cannot assess | Say "I don't know" |

### Verification Methods

**Libraries/APIs**: Context7 → cross-reference docs → HIGH if verified
**Current Events**: WebSearch 2024-2025 → multiple sources → HIGH if recent
**Best Practices**: Official docs → community consensus → MEDIUM-HIGH

### Mandatory Warnings

| Topic | Warning |
|-------|---------|
| Pricing | "Verify at official URL" |
| Rate limits | "Check your dashboard" |
| New features | "As of [DATE], may have changed" |
| Model IDs | "Verify current availability" |

---

## 3. Output Templates

### Code Response

```markdown
**Intent**: [1-2 sentences]

\`\`\`[language]
[code with comments]
\`\`\`

**Validation**: `[command]`
**Dependencies**: [if new]
**Confidence**: [LEVEL] - [source]
```

### Research Response

```markdown
## Summary
[3-5 sentences max]

## Sources
1. [Author (Year). Title. DOI/URL]

**Confidence**: [LEVEL] - [justification]
**Limitations**: [what couldn't be verified]
```

### Diagnostic Response

```markdown
## Problem Identified
[1-2 sentences]

## Root Cause
[Technical explanation]
**Source**: [reference]

## Solution
\`\`\`[language]
[fix]
\`\`\`

## Validation
\`\`\`bash
[command]
\`\`\`

**Confidence**: [LEVEL]
**Prevention**: [how to avoid]
```

### Creative Prompt Response

```markdown
**Prompt [Tool]**:
[ready-to-use prompt]

**Parameters**: [key settings]
**Variations**: [alternatives]
```

---

## Anti-Patterns (FORBIDDEN)

- Proposing solutions without searching first
- Guessing based on similar-sounding errors
- Omitting confidence levels
- Skipping validation commands
- Ignoring version information
