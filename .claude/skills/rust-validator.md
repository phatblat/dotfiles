# Rust Validator Skill

Validate Rust code for correctness, style, and performance issues.

## Capability

Analyzes Rust projects and code for:
- **Compilation** — Check if code compiles without errors
- **Clippy lints** — Detect performance, style, and correctness issues
- **Formatting** — Verify compliance with rustfmt standards
- **Dependencies** — Check for security vulnerabilities and outdated crates

Returns structured issues with locations, severity, and suggestions.

## How to Use This Skill

### Input
```
{
  "action": "validate",
  "projectPath": ".",                    // Cargo project root
  "checks": "all",                       // all|compile|clippy|fmt|audit
  "targets": ["lib", "bin"],             // Cargo targets to check
  "features": ["default"],               // Feature flags to enable
  "toolchain": "stable"                  // stable|nightly|<version>
}
```

### Output

Returns structured validation report:
```
{
  "project": "my-crate",
  "status": "issues",  // ok|issues|error
  "checks": {
    "compile": {
      "status": "ok",
      "message": "Project compiles successfully"
    },
    "clippy": {
      "status": "issues",
      "issues": [
        {
          "file": "src/async_handler.rs",
          "line": 42,
          "level": "warning",
          "code": "async_yields_async",
          "message": "An async function that returns a coroutine is unidiomatic",
          "suggestion": "Consider using `impl Future` or `.await` directly",
          "help_url": "https://rust-lang.github.io/rust-clippy/master/index.html#async_yields_async"
        },
        {
          "file": "src/lib.rs",
          "line": 156,
          "level": "warning",
          "code": "clone_on_copy",
          "message": "Clone on a `Copy` type",
          "suggestion": "Use direct assignment instead of .clone()",
          "help_url": "https://rust-lang.github.io/rust-clippy/master/index.html#clone_on_copy"
        }
      ]
    },
    "fmt": {
      "status": "issues",
      "message": "Code does not match rustfmt standards",
      "files_needing_format": ["src/main.rs", "src/utils.rs"],
      "fix_command": "cargo fmt"
    },
    "audit": {
      "status": "ok",
      "vulnerabilities": 0,
      "outdated": 0
    }
  },
  "summary": "2 clippy warnings, formatting issues in 2 files. No compilation errors.",
  "validationTime": "2.4s"
}
```

## Check Types

### compile

Verifies the Rust project compiles without errors.

**Returns**:
- `status`: ok | error
- `errors`: List of compilation errors with file/line/message
- `warnings`: List of compilation warnings (if any)

Use this to catch errors before running other checks.

### clippy

Runs `cargo clippy` to detect:
- **Performance issues**: Unnecessary clones, inefficient patterns
- **Correctness issues**: Logic errors, unsafe practices
- **Style issues**: Non-idiomatic Rust
- **Async issues**: Common async/await pitfalls (blocking in async, improper spawn usage)
- **Memory issues**: Unnecessary allocations, reference inefficiencies

**Severity levels**:
- `error` — Must fix before shipping
- `warning` — Should fix (common issues)
- `help` — Suggestions for improvement

### fmt

Checks code formatting against `rustfmt` standards.

**Returns**:
- `status`: ok | issues
- `files_needing_format`: List of files not matching standard
- `fix_command`: "cargo fmt" to auto-fix

### audit

Checks dependencies for security vulnerabilities using `cargo-audit`.

**Returns**:
- `vulnerabilities`: Count of known security issues
- `outdated_crates`: Crates with available updates
- `advisory_db`: Version of advisory database used

## Protocol

1. **Receive project path**
2. **Detect Rust project** (Cargo.toml exists)
3. **Run requested checks** in order: compile → clippy → fmt → audit
4. **Collect all issues** with locations and suggestions
5. **Return structured results** (no fixes applied)
6. **Do NOT modify files** (agent's responsibility)

## Constraints

This skill **does not**:
- Modify or reformat code (agent's responsibility)
- Update dependencies
- Fix issues automatically
- Make architectural decisions
- Change public API design
- Install missing tools (assumes cargo, clippy, rustfmt available)

## Example Invocation

**Agent**: "Validate this Rust code before we finalize it"

```
[invoke rust-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "toolchain": "stable"
}

Output:
{
  "project": "my-async-lib",
  "status": "issues",
  "checks": {
    "compile": {
      "status": "ok"
    },
    "clippy": {
      "status": "issues",
      "issues": [
        {
          "file": "src/lib.rs",
          "line": 42,
          "level": "warning",
          "code": "clone_on_copy",
          "suggestion": "Use direct assignment instead of .clone()"
        }
      ]
    },
    "fmt": {
      "status": "ok"
    }
  }
}

Agent then: "I found 1 clippy warning about unnecessary cloning.
Let me fix that by using direct assignment instead of .clone()..."
```

## Common Clippy Codes

| Code | Issue | Fix |
|------|-------|-----|
| `clone_on_copy` | Cloning a Copy type | Use direct assignment |
| `unnecessary_mut` | Unnecessary `mut` | Remove `mut` |
| `inefficient_to_string` | Inefficient string conversion | Use `.to_string()` properly |
| `redundant_clone` | Unnecessary `.clone()` call | Remove clone |
| `async_yields_async` | Async returning another async | Use `impl Future` or await directly |
| `blocking_in_async` | Blocking operation in async | Move to separate thread |
| `manual_let_else` | Verbose pattern matching | Use `let...else` syntax |
| `default_trait_access` | Verbose `Default::default()` | Use `.default()` |

## Error Cases

| Scenario | Response |
|----------|----------|
| No Cargo.toml found | `"Not a Rust project: Cargo.toml not found in [path]"` |
| cargo not found | `"Cargo toolchain not found. Install Rust from https://rustup.rs/"` |
| Compilation fails | `"Compilation failed. Fix errors before running other checks. [error details]"` |
| Invalid target | `"Unknown target: [target]. Available: lib, bin, example, test"` |
| Unknown feature | `"Feature not found: [feature]. Check Cargo.toml"` |

## Integration Notes

- **Used by agents**: rust-expert, code-reviewer, performance-optimizer
- **Returns structured data**: Agent interprets and decides on fixes
- **Respects Cargo.lock**: Tests match production dependencies
- **Feature-aware**: Can validate with specific features enabled
- **Toolchain-aware**: Can validate on stable, beta, or nightly
- **No modification**: Skill reports only; agent handles changes
