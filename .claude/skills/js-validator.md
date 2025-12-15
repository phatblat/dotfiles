# JavaScript/TypeScript Validator Skill

Validate JavaScript and TypeScript projects for code quality, style, and type correctness.

## Capability

Analyzes JavaScript/TypeScript projects for:
- **Linting** — Detect code quality issues (ESLint)
- **Formatting** — Check compliance with Prettier standards
- **Type Checking** — Validate TypeScript types (tsc)
- **Dependencies** — Check for vulnerabilities and outdated packages (npm audit)
- **Testing** — Run tests and capture results (Jest, Vitest, Mocha)

Returns structured validation report with issues, locations, and suggestions.

## How to Use This Skill

### Input
```
{
  "action": "validate",
  "projectPath": ".",                        // Project directory
  "checks": "all",                           // all|lint|format|types|deps|test
  "language": "typescript",                  // javascript|typescript|both
  "strictMode": false,                       // Enable strict linting rules
  "testCoverage": false                      // Include test coverage analysis
}
```

### Output

Returns structured validation report:
```
{
  "project": "my-app",
  "language": "typescript",
  "status": "issues",  // ok|issues|error
  "checks": {
    "lint": {
      "status": "issues",
      "issues": [
        {
          "file": "src/components/Login.tsx",
          "line": 42,
          "column": 10,
          "severity": "error",
          "rule": "no-unused-vars",
          "message": "'response' is assigned a value but never used",
          "suggestion": "Remove unused variable or use it in the code"
        },
        {
          "file": "src/api/client.ts",
          "line": 18,
          "column": 5,
          "severity": "warning",
          "rule": "no-console",
          "message": "Unexpected console statement",
          "suggestion": "Use a proper logging library"
        }
      ],
      "errorCount": 1,
      "warningCount": 1
    },
    "format": {
      "status": "issues",
      "files_needing_format": ["src/utils.ts", "src/components/Login.tsx"],
      "fix_command": "npm run format"
    },
    "types": {
      "status": "error",
      "message": "TypeScript compilation failed",
      "errors": [
        {
          "file": "src/types.ts",
          "line": 25,
          "column": 3,
          "code": "TS2322",
          "message": "Type 'string' is not assignable to type 'number'",
          "suggestion": "Update type definition or value"
        }
      ],
      "errorCount": 1,
      "compileTime": "1.2s"
    },
    "deps": {
      "status": "issues",
      "vulnerabilities": [
        {
          "package": "axios",
          "version": "0.21.1",
          "severity": "moderate",
          "issue": "Server-Side Request Forgery",
          "recommendation": "Update to 0.21.2 or later"
        }
      ],
      "outdated": 3,
      "outdatedPackages": [
        {
          "package": "react",
          "current": "18.2.0",
          "latest": "18.3.1"
        }
      ]
    },
    "test": {
      "status": "ok",
      "passed": 45,
      "failed": 0,
      "skipped": 2,
      "coverage": {
        "lines": 82.5,
        "statements": 81.3,
        "functions": 75.0,
        "branches": 68.2
      },
      "duration": "3.4s"
    }
  },
  "summary": "1 type error, 2 lint issues, 2 files need formatting, 1 security vulnerability, tests passing",
  "validationTime": "5.1s"
}
```

## Check Types

### lint
Runs ESLint to detect code quality issues.

**Common Rules**:
- `no-unused-vars` — Unused variables or imports
- `no-console` — Console statements (warn for production)
- `prefer-const` — Variables that should be const
- `no-var` — Use let/const instead of var
- `eqeqeq` — Use === instead of ==
- `no-undef` — Undefined variables

### format
Checks code formatting against Prettier configuration.

**Returns**:
- Files needing formatting
- Fix command: `npm run format` or `prettier --write .`

### types
Runs TypeScript compiler (tsc) to validate types.

**Common Errors**:
- `TS2322` — Type assignment errors
- `TS2304` — Cannot find name
- `TS2339` — Property does not exist on type
- `TS2345` — Argument type mismatch
- `TS7006` — Implicit any type

### deps
Checks dependencies using `npm audit` or `yarn audit`.

**Returns**:
- Security vulnerabilities with severity
- Outdated packages
- Unused dependencies
- Peer dependency issues

### test
Runs tests using Jest, Vitest, or Mocha.

**Returns**:
- Pass/fail counts
- Test coverage (lines, statements, functions, branches)
- Test duration
- Skipped tests

## Protocol

1. **Receive project path** and validation checks
2. **Detect project type** (package.json, tsconfig.json presence)
3. **Run requested checks** in order: lint → format → types → deps → test
4. **Collect all issues** with locations and suggestions
5. **Return structured report** (no fixes applied)
6. **Do NOT modify files** (agent's responsibility)

## Constraints

This skill **does not**:
- Modify or format code (agent's responsibility)
- Auto-fix lint issues
- Update dependencies
- Install missing tools (assumes npm/yarn, ESLint, Prettier, tsc available)
- Modify package.json or lock files
- Run builds or bundlers (Webpack, Vite, etc.)
- Execute tests with custom configurations beyond defaults

## Common ESLint Rules

| Rule | Code | Description | Fix |
|------|------|-------------|-----|
| Unused variable | `no-unused-vars` | Variable declared but not used | Remove or use variable |
| Console statement | `no-console` | console.log in production code | Use logging library |
| Prefer const | `prefer-const` | Variable never reassigned | Change `let` to `const` |
| No var | `no-var` | Using var instead of let/const | Use `let` or `const` |
| Strict equality | `eqeqeq` | Using == instead of === | Use `===` or `!==` |
| Missing await | `require-await` | Async function without await | Remove async or add await |

## Common TypeScript Errors

| Code | Description | Typical Fix |
|------|-------------|-------------|
| TS2322 | Type not assignable | Update type definition or cast |
| TS2304 | Cannot find name | Import or define the identifier |
| TS2339 | Property does not exist | Check type definition or add property |
| TS2345 | Argument type mismatch | Pass correct type or update signature |
| TS7006 | Implicit any | Add explicit type annotation |
| TS2307 | Cannot find module | Install package or fix import path |

## Example Invocation

**Agent**: "Validate this TypeScript React app before deployment"

```
[invoke js-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "language": "typescript"
}

Output:
{
  "project": "react-app",
  "status": "issues",
  "checks": {
    "lint": {
      "status": "issues",
      "issues": [
        {
          "file": "src/App.tsx",
          "line": 12,
          "rule": "no-unused-vars",
          "message": "'user' is assigned but never used"
        }
      ]
    },
    "format": {
      "status": "ok"
    },
    "types": {
      "status": "ok",
      "compileTime": "1.1s"
    },
    "deps": {
      "status": "ok",
      "vulnerabilities": []
    },
    "test": {
      "status": "ok",
      "passed": 24,
      "coverage": {
        "lines": 85.2
      }
    }
  },
  "summary": "1 lint issue, all tests passing, no type errors"
}
```

## Error Cases

| Scenario | Response |
|----------|----------|
| No package.json found | `"No Node.js project detected. package.json not found."` |
| npm/node not available | `"Node.js not found. Install Node.js 18+."` |
| ESLint not configured | `"ESLint not configured. Run: npm init @eslint/config"` |
| TypeScript not found | `"TypeScript not installed. Run: npm install --save-dev typescript"` |
| Invalid TypeScript config | `"tsconfig.json invalid. Check configuration."` |
| Tests not found | `"No test runner found. Install Jest, Vitest, or Mocha."` |

## Framework Detection

The skill automatically detects:
- **React** — Checks for JSX/TSX, React-specific rules
- **Vue** — Checks for .vue files, Vue-specific linting
- **Angular** — Checks for Angular-specific patterns
- **Next.js** — Detects Next.js configuration
- **Node.js** — Backend-specific rules (no window/document)
- **React Native** — Mobile-specific rules and globals

## Integration Notes

- **Used by agents**: js-expert, code-reviewer, frontend-developer, node-developer
- **Returns structured data**: Validation report with issues and suggestions
- **Framework-aware**: Detects React, Vue, Angular, Next.js, Node.js
- **Comprehensive**: Covers linting, formatting, types, dependencies, testing
- **No modification**: Skill reports only; agent handles changes
- **Dependencies**: Requires Node.js, npm/yarn/pnpm, ESLint, Prettier, TypeScript (for TS projects)
- **Standards-compliant**: Follows JavaScript/TypeScript community best practices
- **Security-aware**: Checks for dependency vulnerabilities
