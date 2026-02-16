# Go Validator Skill

Validate Go projects and code for correctness, style, and dependency health.

## Capability

Analyzes Go projects for:
- **Compilation** — Verify code compiles without errors (go build)
- **Linting** — Detect code quality issues (go vet, golangci-lint)
- **Formatting** — Check compliance with gofmt standards
- **Dependencies** — Validate and audit module dependencies (go mod)
- **Testing** — Run tests and capture coverage (go test)

Returns structured validation report with issues, locations, and suggestions.

## How to Use This Skill

### Input
```
{
  "action": "validate",
  "projectPath": ".",                        // Project directory
  "checks": "all",                           // all|compile|lint|format|deps|test
  "goVersion": "1.21",                       // Target Go version (default: latest)
  "strictMode": false,                       // Enable strict linting
  "testCoverage": false                      // Include test coverage analysis
}
```

### Output

Returns structured validation report:
```
{
  "project": "my-api",
  "goVersion": "1.21",
  "status": "issues",  // ok|issues|error
  "checks": {
    "compile": {
      "status": "error",
      "message": "Build failed",
      "errors": [
        {
          "file": "main.go",
          "line": 42,
          "column": 5,
          "message": "undefined: json (you may have meant 'encoding/json')"
        }
      ],
      "buildTime": "0.3s"
    },
    "lint": {
      "status": "issues",
      "issues": [
        {
          "file": "handlers.go",
          "line": 18,
          "column": 8,
          "severity": "warning",
          "code": "unused",
          "message": "unused variable 'result'",
          "suggestion": "Remove unused variable or assign to blank identifier"
        },
        {
          "file": "config.go",
          "line": 25,
          "column": 1,
          "severity": "error",
          "code": "errcheck",
          "message": "Unchecked error in file.Close()",
          "suggestion": "Add error handling: if err != nil { ... }"
        }
      ]
    },
    "format": {
      "status": "issues",
      "files_needing_format": ["main.go", "handlers.go"],
      "fix_command": "go fmt ./..."
    },
    "deps": {
      "status": "issues",
      "issues": [
        {
          "type": "unused",
          "module": "github.com/unused/lib",
          "version": "v1.0.0",
          "suggestion": "Remove from go.mod"
        },
        {
          "type": "indirect",
          "module": "github.com/transitive/lib",
          "version": "v2.0.0",
          "info": "Indirect dependency, ensure compatibility"
        }
      ],
      "outdated": 2,
      "outdatedPackages": [
        {
          "module": "github.com/go-chi/chi",
          "current": "v5.0.8",
          "latest": "v5.0.10"
        }
      ]
    },
    "test": {
      "status": "ok",
      "passed": 24,
      "failed": 0,
      "skipped": 2,
      "coverage": "78.5%",
      "duration": "2.1s"
    }
  },
  "summary": "Build failed, 2 lint issues, 2 formatting issues, 2 outdated packages, tests passing",
  "validationTime": "3.8s"
}
```

## Check Types

### compile
Compiles project using `go build` to detect compilation errors.

**Returns**:
- Build success/failure status
- Compilation errors with file, line, column
- Build duration

### lint
Runs `go vet` and `golangci-lint` to detect code quality issues.

**Common Issues**:
- `unused` — Unused variables or functions
- `errcheck` — Unchecked error returns (critical pattern in Go)
- `nilcheck` — Potential nil pointer dereference
- `structtag` — Invalid struct tags
- `shadowdecl` — Variable shadowing

### format
Checks code formatting against `gofmt` standards.

**Returns**:
- Files needing formatting
- Fix command: `go fmt ./...`

### deps
Validates Go module dependencies using `go mod`.

**Returns**:
- Unused dependencies
- Indirect/transitive dependencies
- Outdated packages
- Security vulnerabilities (when available)

### test
Runs tests with `go test` and reports results.

**Returns**:
- Pass/fail count
- Test coverage percentage
- Skipped tests
- Test duration

## Protocol

1. **Receive project path** and validation checks
2. **Detect Go project** (go.mod presence)
3. **Run requested checks** in order: compile → lint → format → deps → test
4. **Collect all issues** with locations and suggestions
5. **Return structured report** (no fixes applied)
6. **Do NOT modify files** (agent's responsibility)

## Constraints

This skill **does not**:
- Modify or format code (agent's responsibility)
- Auto-fix issues
- Update dependencies
- Install missing tools (assumes go, golangci-lint available)
- Modify go.mod or go.sum
- Run benchmarks or profiling
- Execute tests with custom flags beyond defaults

## Common Go Linting Issues

| Issue | Code | Description | Fix |
|-------|------|-------------|-----|
| Unused variable | `unused` | Variable declared but not used | Remove or use blank `_` |
| Unchecked error | `errcheck` | Error return value not checked | Add: `if err != nil { ... }` |
| Struct tag error | `structtag` | Invalid struct tag syntax | Fix tag syntax in struct definition |
| Variable shadowing | `shadowdecl` | Variable shadows outer scope | Rename one variable |
| Nil pointer risk | `nilcheck` | Potential nil pointer dereference | Add nil check before use |

## Example Invocation

**Agent**: "Validate this Go project before deployment"

```
[invoke go-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "goVersion": "1.21"
}

Output:
{
  "project": "api-server",
  "status": "issues",
  "checks": {
    "compile": {
      "status": "ok",
      "buildTime": "0.4s"
    },
    "lint": {
      "status": "issues",
      "issues": [
        {
          "file": "main.go",
          "line": 45,
          "code": "errcheck",
          "message": "Unchecked error in response.Write()",
          "suggestion": "Add error handling"
        }
      ]
    },
    "format": {
      "status": "ok"
    },
    "deps": {
      "status": "ok",
      "outdated": 0
    },
    "test": {
      "status": "ok",
      "passed": 18,
      "coverage": "82.3%"
    }
  },
  "summary": "1 lint issue, all tests passing, code formatted correctly"
}
```

## Error Cases

| Scenario | Response |
|----------|----------|
| No Go project found | `"No Go project detected. go.mod not found."` |
| go command not available | `"go command not found. Install Go 1.21+."` |
| golangci-lint not available | `"golangci-lint not installed. Install with: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"` |
| Compilation failed | `"Compilation failed with [N] errors. See details above."` |
| Invalid Go version | `"Invalid Go version: [version]. Supported: 1.19, 1.20, 1.21, 1.22"` |
| Module integrity error | `"go.mod integrity error. Run: go mod tidy"` |

## Integration Notes

- **Used by agents**: go-expert, code-reviewer, performance-optimizer
- **Returns structured data**: Validation report with issues and suggestions
- **Version-aware**: Validates against specified Go version
- **Comprehensive**: Covers compilation, linting, formatting, dependencies, testing
- **No modification**: Skill reports only; agent handles changes
- **Dependencies**: Requires go, golangci-lint, standard Go tools
- **Idiomatic**: Follows Go conventions and best practices
- **Error-aware**: Focuses on Go's error handling patterns
