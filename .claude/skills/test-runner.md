# Test Runner Skill

Execute automated test suites and report results for a project.

## Capability

Detects and executes the appropriate test command for a project based on its build system, then captures and returns raw test output.

## Supported Frameworks

- **Make**: `make test`
- **Node.js/npm**: `npm test`
- **Python**: `pytest` or `python -m pytest`
- **Rust**: `cargo test`
- **Go**: `go test ./...`
- **Java/Gradle**: `gradle test` or `./gradlew test`
- **Java/Maven**: `mvn test`
- **.NET**: `dotnet test`
- **Ruby**: `rake test` or `bundle exec rspec`

## How to Use This Skill

### Input
```
{
  "action": "run-tests",
  "testFramework": "auto",  // or specify: "cargo", "npm", "go", "pytest", etc.
  "args": "",               // optional: additional test args (e.g., "-v", "--coverage")
  "workDir": "."            // optional: override working directory
}
```

### Output
The skill returns:
- **command**: The exact test command executed
- **exitCode**: 0 for pass, non-zero for failure
- **stdout**: Complete unmodified test output
- **stderr**: Error messages if any
- **duration**: Time taken (if available)

## Protocol

1. **Detection** (when `testFramework: "auto"`):
   - Check for build files in order: `Makefile`, `Cargo.toml`, `go.mod`, `package.json`, `pyproject.toml` / `pytest.ini`, `pom.xml`, `build.gradle`, `*.csproj`, `Gemfile`
   - Return detected framework and available test commands
   - If multiple frameworks exist, ask which to use

2. **Execution**:
   - Run the test command in the specified working directory
   - Capture complete stdout and stderr
   - Preserve all formatting (colors, indentation, tables)
   - Report exit code exactly as returned by the test runner

3. **Reporting**:
   - Display command being run: `$ <command>`
   - Show raw output in a code block
   - Include summary: `exit code: X | duration: Y seconds`
   - Do NOT interpret, analyze, or summarize results

## Constraints

This skill **does not**:
- Analyze test failures or diagnose issues
- Suggest fixes for failing tests
- Modify test files or code
- Run setup/teardown steps (reports if needed)
- Troubleshoot missing dependencies
- Provide test coverage analysis or interpretation

## Example Invocation

**When an agent needs to run tests:**

```
Agent: I'll run the test suite to verify the implementation.

Skills: [invoke test-runner]
Input: {
  "action": "run-tests",
  "testFramework": "auto"
}

Output:
command: "cargo test"
exitCode: 0
stdout: |
   running 42 tests
   test result: ok. 42 passed; 0 failed; 0 ignored
duration: 3.24s
```

**Agent then reports:** "Tests passed: 42/42 ✓"

## Error Cases

| Scenario | Response |
|----------|----------|
| No test framework detected | `"No test framework found. Check project structure."` |
| Multiple frameworks available | Ask: `"Found Makefile and package.json. Which test command?"` |
| Missing dependencies | `"Test execution failed: [error message]. Dependencies may be missing."` |
| Test timeout | `"Test execution timeout after X seconds"` |
| Invalid working directory | `"Working directory not found: [path]"` |

## Integration Notes

- **Use in agents**: When an agent needs test feedback, invoke this skill
- **Return to agent**: Agent interprets results and decides next steps
- **No blocking**: If tests fail, skill reports failure; agent decides remediation
- **Parallel tests**: Pass `--jobs` or equivalent in `args` field if parallel execution needed
