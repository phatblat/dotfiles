# Shell Validator Skill

Validate shell scripts for correctness, portability, and best practices.

## Capability

Analyzes shell scripts (Bash/Zsh/sh) and reports issues related to:
- **Syntax errors** (via shellcheck)
- **Portability** (macOS vs Linux differences)
- **Best practices** (coding standards, security)
- **Formatting** (shfmt standards)

Returns structured issues with locations, severity, and suggestions.

## Supported Shells

- Bash (#!/bin/bash)
- POSIX sh (#!/bin/sh)
- Zsh (#!/bin/zsh)

## How to Use This Skill

### Input
```
{
  "action": "validate",
  "scriptPath": "path/to/script.sh",          // Script to validate
  "checks": "all",                             // all|syntax|portability|formatting|security
  "targetPlatforms": ["macos", "linux"],       // Which platforms to check
  "shellType": "bash"                          // bash|sh|zsh (auto-detect if omitted)
}
```

### Output

Returns structured validation report:
```
{
  "script": "path/to/script.sh",
  "status": "issues",  // pass|issues|error
  "shellType": "bash",
  "issues": [
    {
      "type": "syntax",
      "code": "SC2086",
      "severity": "error",
      "line": 42,
      "message": "Double quote to prevent globbing and word splitting",
      "suggestion": 'Change: rm $file → rm "$file"',
      "platforms": ["all"]
    },
    {
      "type": "portability",
      "code": "P001",
      "severity": "warning",
      "line": 28,
      "message": "sed -i syntax differs between macOS and Linux",
      "suggestion": 'Use: sed -i "" (macOS) vs sed -i (Linux) or use portable alternative',
      "platforms": ["macos", "linux"]
    },
    {
      "type": "formatting",
      "code": "FMT001",
      "severity": "info",
      "line": 15,
      "message": "Inconsistent indentation (expected 2 spaces, found 4)",
      "suggestion": "Run: shfmt -w script.sh"
    }
  ],
  "summary": "3 issues: 1 error, 1 warning, 1 info",
  "validationTime": "0.3s"
}
```

## Check Types

### syntax (via shellcheck)

Detects:
- Variable quoting issues
- Command substitution problems
- Uninitialized variables
- Logic errors
- Array issues

**Severity codes**:
- SC2086: Unquoted variable
- SC2181: Checking exit code of grep
- SC3010: In POSIX sh, use [ ] not [[ ]]
- SC2046: Quote to avoid word splitting
- etc.

### portability

Detects:
- **sed**: BSD vs GNU differences (`-i ''` vs `-i`)
- **date**: Different flag syntax between macOS/Linux
- **grep**: Extended regex (`-E` portable, `-P` GNU-only)
- **readlink**: Not available on all systems
- **stat**: Different output formats
- **find**: Varying option support
- **sort**: Different numeric sort flags
- **awk/sed**: GNU vs BSD behavior differences
- **test operators**: POSIX vs bash-specific

**Severity**: usually `warning` (can work with fallbacks)

### best-practices

Detects:
- Missing `set -euo pipefail` in bash
- Missing shebang
- Unquoted variable expansions
- Missing error handling
- No function documentation
- Hardcoded paths instead of variables
- Missing input validation

### security

Detects:
- Command injection risks
- Unquoted variables in eval/exec
- Insufficient input validation
- World-writable temp files
- Unsafe use of $IFS
- Credentials in script or environment

### formatting

Checks:
- Indentation consistency (tabs vs spaces)
- Line length
- Blank line placement
- shfmt compliance

## Protocol

1. **Receive script path or content**
2. **Detect shell type** from shebang (or use provided)
3. **Run shellcheck** with appropriate shell dialect
4. **Check portability** for specified platforms
5. **Check formatting** against shfmt standard
6. **Return structured issues** with locations and suggestions
7. **Do NOT modify the script** (agent's responsibility)

## Constraints

This skill **does not**:
- Modify or rewrite scripts (agent's responsibility)
- Install missing tools (assumes shellcheck/shfmt available)
- Execute scripts
- Make architectural decisions
- Suggest algorithm changes
- Format output other than JSON/structured format

## Example Invocation

**Agent**: "Validate this script for macOS and Linux compatibility"

```
[invoke shell-validator]
input: {
  "action": "validate",
  "scriptPath": "deploy.sh",
  "checks": "all",
  "targetPlatforms": ["macos", "linux"]
}

Output:
{
  "script": "deploy.sh",
  "status": "issues",
  "issues": [
    {
      "type": "portability",
      "severity": "warning",
      "line": 18,
      "message": "sed -i syntax differs between macOS and Linux",
      "suggestion": "Change: sed -i 's/foo/bar/' file.txt"
    },
    {
      "type": "syntax",
      "severity": "error",
      "line": 42,
      "message": "Double quote to prevent globbing",
      "suggestion": 'Change: rm $file → rm "$file"'
    }
  ],
  "summary": "2 issues: 1 error, 1 warning"
}

Agent then: "I found 2 issues. Let me fix the sed command for portability and
add quotes around the variable. I'll rewrite the script now..."
```

## Error Cases

| Scenario | Response |
|----------|----------|
| Script not found | `"Script not found: [path]"` |
| shellcheck not installed | `"shellcheck required but not found. Install with: brew install shellcheck"` |
| shfmt not installed | `"shfmt required for formatting checks. Install with: brew install shfmt"` |
| Invalid shell type | `"Unknown shell type: [type]. Use: bash, sh, or zsh"` |
| Unreadable script | `"Permission denied reading: [path]"` |

## Integration Notes

- **Used by agents**: shell-expert, script-reviewer, automation-developer
- **Returns structured data**: Agent interprets and decides on fixes
- **Respects local config**: Uses shellcheck.cfg if present
- **No formatting by default**: Suggest shfmt commands, don't auto-apply
- **Platform-aware**: Detects and warns about OS-specific issues
