# Swift Validator

Validate Swift code for correctness, style, and build integrity across Swift Package Manager projects and Xcode projects.

## Capability

This skill validates Swift codebases using SwiftLint, SwiftFormat, the Swift compiler, and Xcode build tools. It detects project structure automatically and applies appropriate validation for iOS, macOS, watchOS, and tvOS applications.

## Supported Project Types

- **Swift Package Manager (SPM)**: Projects with `Package.swift`
- **Xcode Projects**: Single `.xcodeproj` files
- **Xcode Workspaces**: Multi-project `.xcworkspace` files
- **Standalone Swift files**: Single `.swift` files for script validation

## Supported Checks

- **compile** - Swift compiler syntax and type checking
- **lint** - SwiftLint style and best practice rules
- **format** - SwiftFormat code formatting compliance
- **build** - Full Xcode build (for .xcodeproj/.xcworkspace)
- **deps** - Swift Package Manager dependency resolution
- **test** - XCTest suite execution with results
- **all** - Run all applicable checks

## Usage Protocol

Agents invoke this skill by specifying validation parameters:

```json
{
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "scheme": "MyApp",
  "configuration": "Debug",
  "platform": "iOS Simulator",
  "swiftVersion": "5.9"
}
```

### Parameters

- **action** (required): Always `"validate"`
- **projectPath** (required): Path to project root (containing Package.swift or .xcodeproj)
- **checks** (required): Comma-separated list or `"all"` (e.g., `"lint,format"`, `"compile"`, `"all"`)
- **scheme** (optional): Xcode scheme name (required for .xcodeproj/.xcworkspace builds)
- **configuration** (optional): Build configuration (`"Debug"` or `"Release"`, default: `"Debug"`)
- **platform** (optional): Target platform (`"iOS Simulator"`, `"macOS"`, default: auto-detect)
- **swiftVersion** (optional): Swift language version (e.g., `"5.9"`, default: project default)
- **swiftlintConfig** (optional): Path to custom `.swiftlint.yml` config
- **swiftformatConfig** (optional): Path to custom `.swiftformat` config

## Output Format

Returns a structured JSON validation report:

```json
{
  "validationReport": {
    "timestamp": "2025-12-14T13:15:00Z",
    "projectType": "xcode-project",
    "projectPath": "/path/to/MyApp.xcodeproj",
    "swiftVersion": "5.9",
    "checks": ["compile", "lint", "format", "build"],
    "overallStatus": "failed",
    "summary": {
      "totalIssues": 15,
      "errors": 3,
      "warnings": 12,
      "buildSucceeded": false
    },
    "results": {
      "compile": { ... },
      "lint": { ... },
      "format": { ... },
      "build": { ... }
    }
  }
}
```

### Compile Results

```json
{
  "compile": {
    "status": "failed",
    "exitCode": 1,
    "duration": "2.3s",
    "errors": [
      {
        "file": "Sources/App/ContentView.swift",
        "line": 45,
        "column": 12,
        "severity": "error",
        "message": "Cannot convert value of type 'String' to expected argument type 'Int'",
        "code": "type-mismatch"
      }
    ],
    "warnings": [
      {
        "file": "Sources/App/Utilities.swift",
        "line": 23,
        "column": 9,
        "severity": "warning",
        "message": "Immutable value 'result' was never used; consider replacing with '_'",
        "code": "unused-value"
      }
    ]
  }
}
```

### Lint Results (SwiftLint)

```json
{
  "lint": {
    "status": "warning",
    "exitCode": 0,
    "duration": "1.2s",
    "configFile": ".swiftlint.yml",
    "totalViolations": 8,
    "issues": [
      {
        "file": "Sources/App/ViewModel.swift",
        "line": 67,
        "column": 1,
        "severity": "warning",
        "message": "Line should be 120 characters or less; currently it is 145 characters",
        "rule": "line_length",
        "ruleType": "style"
      },
      {
        "file": "Sources/App/NetworkManager.swift",
        "line": 34,
        "column": 5,
        "severity": "error",
        "message": "Force unwrapping should be avoided",
        "rule": "force_unwrapping",
        "ruleType": "idiomatic"
      }
    ]
  }
}
```

### Format Results (SwiftFormat)

```json
{
  "format": {
    "status": "failed",
    "exitCode": 1,
    "duration": "0.8s",
    "configFile": ".swiftformat",
    "formattingIssues": [
      {
        "file": "Sources/App/DataModel.swift",
        "line": 12,
        "issue": "Incorrect indentation (expected 4 spaces, found 2)",
        "rule": "indent"
      },
      {
        "file": "Sources/App/Extensions.swift",
        "line": 45,
        "issue": "Missing space after colon in type annotation",
        "rule": "spaceAroundOperators"
      }
    ]
  }
}
```

### Build Results (Xcode)

```json
{
  "build": {
    "status": "failed",
    "exitCode": 65,
    "duration": "45.2s",
    "scheme": "MyApp",
    "configuration": "Debug",
    "platform": "iOS Simulator",
    "sdk": "iphonesimulator17.2",
    "errors": [
      {
        "file": "MyApp/SceneDelegate.swift",
        "line": 28,
        "message": "Use of unresolved identifier 'windowScen'",
        "type": "compile-error"
      }
    ],
    "warnings": [
      {
        "message": "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 13.0, but the range of supported deployment target versions is 14.0 to 17.2.99",
        "type": "build-warning"
      }
    ]
  }
}
```

### Dependency Results (SPM)

```json
{
  "deps": {
    "status": "success",
    "exitCode": 0,
    "duration": "3.1s",
    "packageFile": "Package.swift",
    "dependencies": [
      {
        "name": "Alamofire",
        "version": "5.8.1",
        "status": "resolved"
      },
      {
        "name": "SwiftLint",
        "version": "0.54.0",
        "status": "resolved"
      }
    ],
    "issues": []
  }
}
```

### Test Results (XCTest)

```json
{
  "test": {
    "status": "passed",
    "exitCode": 0,
    "duration": "12.5s",
    "totalTests": 47,
    "passed": 47,
    "failed": 0,
    "skipped": 2,
    "testSuites": [
      {
        "name": "MyAppTests",
        "tests": 25,
        "passed": 25,
        "failed": 0
      },
      {
        "name": "NetworkTests",
        "tests": 22,
        "passed": 22,
        "failed": 0
      }
    ]
  }
}
```

## Common Swift Issues Detected

### Compiler Errors
- **Type Mismatches**: Incorrect type conversions, missing protocol conformance
- **Unresolved Identifiers**: Typos, missing imports, incorrect namespacing
- **Optional Handling**: Force unwrapping nil values, missing optional binding
- **Access Control**: Private/internal/public visibility violations
- **Memory Issues**: Retain cycles, weak/unowned reference errors

### SwiftLint Rules (Common)
- **force_unwrapping**: Avoid `!` force unwrapping
- **line_length**: Keep lines under 120 characters
- **trailing_whitespace**: Remove trailing spaces
- **identifier_name**: Follow naming conventions (camelCase)
- **unused_closure_parameter**: Use `_` for unused closure parameters
- **force_cast**: Avoid `as!` force casting
- **large_tuple**: Limit tuple size to 2-3 elements
- **function_body_length**: Keep functions under 40 lines

### SwiftFormat Rules
- **indent**: 4 spaces or 1 tab consistently
- **spaceAroundOperators**: Space around `+`, `-`, `=`, etc.
- **redundantParens**: Remove unnecessary parentheses
- **trailingCommas**: Consistent comma placement in arrays/dicts
- **braces**: Opening brace style (K&R vs Allman)

## Project Detection

The skill automatically detects project structure:

1. **SPM**: Looks for `Package.swift` in project root
2. **Xcode Project**: Looks for `*.xcodeproj` directory
3. **Xcode Workspace**: Looks for `*.xcworkspace` directory (takes precedence over .xcodeproj)
4. **Standalone**: Single `.swift` file provided

## Tool Requirements

- **Swift Compiler**: `swiftc` or Xcode Command Line Tools
- **SwiftLint**: Install via `brew install swiftlint` or `mint install realm/SwiftLint`
- **SwiftFormat**: Install via `brew install swiftformat` or `mint install nicklockwood/SwiftFormat`
- **Xcode**: Required for building `.xcodeproj`/`.xcworkspace` projects
- **xcodebuild**: Part of Xcode Command Line Tools

## Constraints

This skill does NOT:
- Modify or reformat code automatically
- Auto-fix SwiftLint violations
- Apply SwiftFormat changes
- Resolve dependency conflicts
- Fix compilation errors
- Install missing tools
- Create Xcode schemes or configurations
- Analyze runtime behavior or crashes

## Error Handling

Returns structured error information for:

- **Missing tools**: SwiftLint, SwiftFormat, or Xcode not installed
- **Invalid project**: No Package.swift, .xcodeproj, or .xcworkspace found
- **Build failures**: Compilation errors, linking errors, resource issues
- **Configuration errors**: Invalid scheme, missing platform SDK
- **Timeout**: Builds exceeding 10 minutes
- **Tool crashes**: SwiftLint or SwiftFormat process failures

Example error response:

```json
{
  "error": {
    "type": "missing-tool",
    "message": "SwiftLint not found. Install with: brew install swiftlint",
    "tool": "swiftlint",
    "installCommand": "brew install swiftlint"
  }
}
```

## Fixing Common Issues

### Force Unwrapping (force_unwrapping)
```swift
// ❌ Violates rule
let name = user.name!

// ✅ Use optional binding
if let name = user.name {
    print(name)
}

// ✅ Use nil coalescing
let name = user.name ?? "Unknown"
```

### Force Casting (force_cast)
```swift
// ❌ Violates rule
let view = subview as! UILabel

// ✅ Use conditional casting
guard let view = subview as? UILabel else { return }
```

### Line Length (line_length)
```swift
// ❌ Line too long
func fetchUserData(userId: String, includeProfile: Bool, includePreferences: Bool, includeHistory: Bool, completionHandler: @escaping (Result<User, Error>) -> Void)

// ✅ Break into multiple lines
func fetchUserData(
    userId: String,
    includeProfile: Bool,
    includePreferences: Bool,
    includeHistory: Bool,
    completionHandler: @escaping (Result<User, Error>) -> Void
)
```

### Trailing Whitespace (trailing_whitespace)
```swift
// ❌ Has trailing spaces
let name = "John"

// ✅ No trailing spaces
let name = "John"
```

### Identifier Naming (identifier_name)
```swift
// ❌ Poor naming
let a = "test"
func x() {}

// ✅ Descriptive names
let userName = "test"
func fetchUserData() {}
```
