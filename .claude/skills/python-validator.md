# Python Validator Skill

Validate Python code for style, type correctness, and security issues.

## Capability

Analyzes Python projects and code for:
- **Formatting** — Check compliance with Black/PEP 8 standards
- **Linting** — Detect code quality issues (Pylint/Ruff)
- **Type checking** — Verify type hints correctness (mypy)
- **Security** — Find security vulnerabilities (bandit)
- **Dependencies** — Check for outdated or vulnerable packages

Returns structured issues with locations, severity, and suggestions.

## How to Use This Skill

### Input
```
{
  "action": "validate",
  "projectPath": ".",                    // Project root or file
  "checks": "all",                       // all|fmt|lint|types|security|deps
  "pythonVersion": "3.13",               // Target Python version
  "strictMode": false                    // Enable strict type checking
}
```

### Output

Returns structured validation report:
```
{
  "project": "my-package",
  "pythonVersion": "3.13",
  "status": "issues",  // ok|issues|error
  "checks": {
    "fmt": {
      "status": "issues",
      "message": "Code does not match Black formatting",
      "files_needing_format": ["src/main.py", "tests/test_utils.py"],
      "fix_command": "black ."
    },
    "lint": {
      "status": "issues",
      "issues": [
        {
          "file": "src/handlers.py",
          "line": 42,
          "column": 8,
          "code": "C0103",
          "severity": "warning",
          "message": "Invalid variable name 'X' (should match pattern)",
          "suggestion": "Rename variable to match PEP 8 snake_case convention"
        },
        {
          "file": "src/utils.py",
          "line": 156,
          "column": 0,
          "code": "W0612",
          "severity": "warning",
          "message": "Unused variable 'result'",
          "suggestion": "Remove unused variable or use it"
        }
      ]
    },
    "types": {
      "status": "issues",
      "issues": [
        {
          "file": "src/payment.py",
          "line": 18,
          "column": 4,
          "severity": "error",
          "message": "Incompatible types in assignment (expression has type \"int\", variable has type \"str\")",
          "suggestion": "Fix type mismatch: ensure variable type matches assigned value"
        }
      ]
    },
    "security": {
      "status": "issues",
      "vulnerabilities": [
        {
          "file": "src/db.py",
          "line": 34,
          "severity": "high",
          "code": "B608",
          "message": "Possible SQL injection vector through string-based query",
          "suggestion": "Use parameterized queries instead of string concatenation"
        }
      ]
    },
    "deps": {
      "status": "ok",
      "vulnerabilities": 0,
      "outdated": 2,
      "outdatedPackages": [
        {
          "name": "requests",
          "current": "2.28.0",
          "latest": "2.31.0"
        }
      ]
    }
  },
  "summary": "2 formatting issues, 4 lint warnings, 1 type error, 1 security issue, 2 outdated packages",
  "validationTime": "3.2s"
}
```

## Check Types

### fmt (Formatting)

Checks code formatting against Black/PEP 8 standards.

**Returns**:
- `status`: ok | issues
- `files_needing_format`: Files that don't match Black standard
- `fix_command`: "black ." to auto-fix

### lint (Linting)

Runs Pylint/Ruff to detect code quality issues.

**Common issues**:
- C0103: Invalid variable/function name (not snake_case)
- W0612: Unused variable
- R0903: Too few public methods
- E1101: No member in module/class
- W0614: Wildcard import (from x import *)

### types (Type Checking)

Runs mypy to verify type hints.

**Returns**:
- `status`: ok | issues | error
- `issues`: Type mismatches with locations
- `strictMode`: Whether strict checking was enabled

### security (Security)

Runs bandit to find security vulnerabilities.

**Common issues**:
- B101: Assert used (test only)
- B201: Flask debug enabled
- B301: Pickle usage (security risk)
- B602: Shell injection risk
- B608: SQL injection risk

### deps (Dependencies)

Checks dependencies for vulnerabilities and updates.

**Returns**:
- `vulnerabilities`: Count of known issues
- `outdated`: Count of outdated packages
- `outdatedPackages`: List with current vs latest versions

## Protocol

1. **Receive project path**
2. **Detect Python project** (setup.py, pyproject.toml, or .py files)
3. **Run requested checks** in order: fmt → lint → types → security → deps
4. **Collect all issues** with locations and suggestions
5. **Return structured results** (no fixes applied)
6. **Do NOT modify files** (agent's responsibility)

## Constraints

This skill **does not**:
- Modify or reformat code (agent's responsibility)
- Auto-fix issues
- Update dependencies
- Install missing tools (assumes black, pylint, mypy, bandit available)
- Modify code structure or logic

## Example Invocation

**Agent**: "Validate this Python code before we finalize it"

```
[invoke python-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "pythonVersion": "3.13"
}

Output:
{
  "project": "payment-service",
  "pythonVersion": "3.13",
  "status": "issues",
  "checks": {
    "fmt": {
      "status": "ok"
    },
    "lint": {
      "status": "issues",
      "issues": [
        {
          "file": "src/handlers.py",
          "line": 42,
          "code": "W0612",
          "message": "Unused variable 'result'"
        }
      ]
    },
    "types": {
      "status": "ok"
    },
    "security": {
      "status": "ok"
    },
    "deps": {
      "status": "ok",
      "outdated": 1
    }
  },
  "summary": "1 lint warning, 1 outdated package"
}

Agent then: "I found 1 unused variable warning. Let me fix that
and update the outdated package..."
```

## Common Pylint Codes

| Code | Issue | Fix |
|------|-------|-----|
| C0103 | Invalid name | Use snake_case for functions/vars |
| W0612 | Unused variable | Remove or use the variable |
| R0903 | Too few methods | Move to function or add methods |
| E1101 | No member | Check object type/import |
| W0614 | Wildcard import | Use explicit imports |
| C0301 | Line too long | Break into multiple lines |
| W0231 | __init__ not called | Call super().__init__() |

## Error Cases

| Scenario | Response |
|----------|----------|
| No Python project found | `"No Python project detected. No setup.py or .py files found."` |
| black not installed | `"black tool not found. Install with: pip install black"` |
| pylint not installed | `"pylint tool not found. Install with: pip install pylint"` |
| mypy not installed | `"mypy tool not found. Install with: pip install mypy"` |
| bandit not installed | `"bandit tool not found. Install with: pip install bandit"` |
| Invalid Python version | `"Invalid Python version: [version]. Use format: 3.9, 3.10, 3.11, 3.12, 3.13"` |
| Missing dependencies | `"Cannot validate: dependencies not installed. Run: pip install -r requirements.txt"` |

## Integration Notes

- **Used by agents**: python-expert, code-reviewer, security-auditor
- **Returns structured data**: Agent interprets and decides on fixes
- **Version-aware**: Validates against specified Python version
- **Strict mode**: Optional strict type checking for production code
- **No modification**: Skill reports only; agent handles changes
- **Dependencies**: Requires black, pylint/ruff, mypy, bandit, pip-audit
