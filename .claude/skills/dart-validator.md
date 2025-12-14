# Dart Validator

Validate Flutter and Dart projects for correctness, style, and build integrity across mobile, web, and desktop platforms.

## Capability

This skill validates Dart and Flutter projects using Dart SDK tools: dart analyze, dart format, flutter build, and test execution. It supports Flutter apps, Dart packages, and projects with FFI (Foreign Function Interface) native code integration.

## Supported Project Types

- **Flutter Applications**: Mobile (iOS/Android), web, desktop (macOS/Windows/Linux)
- **Dart Packages**: Pure Dart libraries and packages
- **Flutter Plugins**: Packages with platform-specific implementations
- **Flutter with FFI**: Projects using dart:ffi for C library integration

## Supported Checks

- **analyze** - Dart static analysis (dart analyze)
- **format** - Dart code formatting compliance (dart format)
- **build** - Flutter build for target platform
- **test** - Unit, widget, and integration tests
- **pub** - Package dependency resolution and validation
- **ffi** - FFI bindings validation (if applicable)
- **all** - Run all applicable checks

## Usage Protocol

Agents invoke this skill by specifying validation parameters:

```json
{
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "platform": "android",
  "buildMode": "debug"
}
```

### Parameters

- **action** (required): Always `"validate"`
- **projectPath** (required): Path to project root (containing pubspec.yaml)
- **checks** (required): Comma-separated list or `"all"` (e.g., `"analyze,format"`, `"build"`, `"all"`)
- **platform** (optional): Target platform (`"android"`, `"ios"`, `"web"`, `"macos"`, `"windows"`, `"linux"`)
- **buildMode** (optional): Build mode (`"debug"`, `"profile"`, `"release"`, default: `"debug"`)
- **fatalInfos** (optional): Treat info-level issues as errors (default: `false`)

## Output Format

Returns a structured JSON validation report:

```json
{
  "validationReport": {
    "timestamp": "2025-12-14T16:00:00Z",
    "projectType": "flutter-app",
    "projectPath": "/path/to/flutter-project",
    "dartVersion": "3.5.0",
    "flutterVersion": "3.24.0",
    "checks": ["analyze", "format", "build", "test", "pub"],
    "overallStatus": "warning",
    "summary": {
      "totalIssues": 14,
      "errors": 2,
      "warnings": 10,
      "info": 2,
      "buildSucceeded": true
    },
    "results": {
      "analyze": { ... },
      "format": { ... },
      "build": { ... },
      "test": { ... },
      "pub": { ... }
    }
  }
}
```

### Analyze Results (dart analyze)

```json
{
  "analyze": {
    "status": "warning",
    "exitCode": 0,
    "duration": "3.2s",
    "totalIssues": 12,
    "issues": [
      {
        "file": "lib/main.dart",
        "line": 45,
        "column": 12,
        "severity": "error",
        "message": "Undefined name 'viewModel'",
        "code": "undefined_identifier",
        "url": "https://dart.dev/tools/diagnostic-messages#undefined_identifier"
      },
      {
        "file": "lib/widgets/button.dart",
        "line": 23,
        "column": 5,
        "severity": "warning",
        "message": "The value of the local variable 'result' isn't used",
        "code": "unused_local_variable",
        "url": "https://dart.dev/tools/diagnostic-messages#unused_local_variable"
      },
      {
        "file": "lib/utils/helpers.dart",
        "line": 67,
        "column": 9,
        "severity": "info",
        "message": "The function 'calculateTotal' could have a const constructor",
        "code": "prefer_const_constructors",
        "url": "https://dart.dev/tools/diagnostic-messages#prefer_const_constructors"
      }
    ]
  }
}
```

### Format Results (dart format)

```json
{
  "format": {
    "status": "failed",
    "exitCode": 1,
    "duration": "0.8s",
    "totalViolations": 8,
    "issues": [
      {
        "file": "lib/models/user.dart",
        "line": 15,
        "issue": "Line is longer than 80 characters (currently 95)",
        "fix": "Run: dart format lib/models/user.dart"
      },
      {
        "file": "lib/services/api.dart",
        "line": 28,
        "issue": "Incorrect indentation (expected 2 spaces, found 4)",
        "fix": "Run: dart format lib/services/api.dart"
      }
    ]
  }
}
```

### Build Results (flutter build)

```json
{
  "build": {
    "status": "success",
    "exitCode": 0,
    "duration": "42.5s",
    "platform": "android",
    "buildMode": "debug",
    "outputPath": "build/app/outputs/flutter-apk/app-debug.apk",
    "outputSize": "18.3 MB",
    "dartVersion": "3.5.0",
    "flutterVersion": "3.24.0",
    "warnings": []
  }
}
```

### Test Results

```json
{
  "test": {
    "status": "failed",
    "exitCode": 1,
    "duration": "8.5s",
    "totalTests": 42,
    "passed": 39,
    "failed": 3,
    "skipped": 0,
    "testTypes": ["unit", "widget"],
    "failures": [
      {
        "testFile": "test/widgets/login_form_test.dart",
        "testName": "LoginForm validates email format",
        "message": "Expected: <true>\n  Actual: <false>",
        "stackTrace": "package:flutter_test/src/widget_tester.dart 455:16\ntest/widgets/login_form_test.dart:42:5"
      }
    ]
  }
}
```

### Pub Results (Package Dependencies)

```json
{
  "pub": {
    "status": "success",
    "exitCode": 0,
    "duration": "2.3s",
    "dependencies": [
      {
        "name": "provider",
        "version": "6.1.1",
        "type": "direct",
        "status": "resolved"
      },
      {
        "name": "http",
        "version": "1.1.2",
        "type": "direct",
        "status": "resolved"
      }
    ],
    "issues": []
  }
}
```

### FFI Results (Native Bindings)

```json
{
  "ffi": {
    "status": "success",
    "exitCode": 0,
    "duration": "1.2s",
    "bindingsFile": "lib/src/native_bindings.dart",
    "nativeLibraries": [
      {
        "name": "libnative.so",
        "platform": "android",
        "path": "android/src/main/jniLibs/arm64-v8a/libnative.so"
      }
    ],
    "issues": []
  }
}
```

## Common Dart/Flutter Issues Detected

### Dart Analyzer Issues
- **undefined_identifier**: Using undeclared variables or functions
- **unused_local_variable**: Variables declared but never used
- **prefer_const_constructors**: Constructors that could be const
- **prefer_final_fields**: Mutable fields that should be final
- **avoid_print**: Using print() instead of debugPrint()
- **prefer_single_quotes**: Using double quotes instead of single
- **missing_required_param**: Missing required named parameters
- **invalid_override_different_signature**: Override with different signature

### Format Issues
- **Line length**: Lines exceeding 80 characters
- **Indentation**: Incorrect spacing (should be 2 spaces)
- **Trailing commas**: Missing trailing commas in multi-line lists
- **Blank lines**: Incorrect blank line usage

### Build Issues
- **Missing assets**: Assets referenced but not in pubspec.yaml
- **Plugin conflicts**: Incompatible plugin versions
- **Platform-specific errors**: iOS/Android build configuration issues
- **Gradle version conflicts**: Android build tool version mismatches

### Test Issues
- **Widget test failures**: UI tests failing due to state changes
- **Async test issues**: Tests not properly awaiting async operations
- **Golden test mismatches**: UI snapshot differences

## Project Detection

The skill automatically detects project structure:

1. **Flutter Project**: Looks for `pubspec.yaml` with Flutter SDK dependency
2. **Dart Package**: Pure Dart project without Flutter dependency
3. **FFI Integration**: Checks for `dart:ffi` imports and native library references
4. **Platform Support**: Identifies iOS, Android, web, desktop targets

## Tool Requirements

- **Dart SDK**: Dart 3.0 or later (included with Flutter SDK)
- **Flutter SDK**: Flutter 3.0 or later (for Flutter projects)
- **dart analyze**: Part of Dart SDK
- **dart format**: Part of Dart SDK
- **flutter build**: Part of Flutter SDK
- **Platform SDKs** (optional): Android SDK, Xcode (for builds)

## Constraints

This skill does NOT:
- Modify or reformat code automatically
- Auto-fix analyzer warnings
- Apply dart format changes
- Fix compilation errors
- Resolve dependency conflicts
- Install missing packages or SDKs
- Generate missing files
- Analyze runtime behavior or crashes
- Run tests on physical devices/emulators
- Build for platforms without required SDKs

## Error Handling

Returns structured error information for:

- **Missing Dart/Flutter SDK**: SDK not installed or not in PATH
- **Invalid project**: No pubspec.yaml found
- **Build failures**: Platform-specific build errors
- **Configuration errors**: Invalid pubspec.yaml, missing dependencies
- **Timeout**: Builds exceeding 15 minutes
- **Tool crashes**: Dart/Flutter CLI failures

Example error response:

```json
{
  "error": {
    "type": "missing-flutter-sdk",
    "message": "Flutter SDK not found. Install from https://flutter.dev/docs/get-started/install",
    "installCommand": "Follow installation guide at https://flutter.dev/docs/get-started/install"
  }
}
```

## Fixing Common Issues

### Undefined Identifier (undefined_identifier)
```dart
// ❌ Missing import
final viewModel = UserViewModel();

// ✅ Add import
import 'package:myapp/viewmodels/user_viewmodel.dart';
final viewModel = UserViewModel();
```

### Unused Local Variable (unused_local_variable)
```dart
// ❌ Variable declared but never used
void calculate() {
  final result = 10 + 5;
  print('Done');
}

// ✅ Remove unused variable or use it
void calculate() {
  final result = 10 + 5;
  print('Result: $result');
}
```

### Prefer Const Constructors (prefer_const_constructors)
```dart
// ❌ Non-const constructor that could be const
Widget build(BuildContext context) {
  return Container(
    child: Text('Hello'),
  );
}

// ✅ Use const constructors
Widget build(BuildContext context) {
  return const Container(
    child: Text('Hello'),
  );
}
```

### Prefer Final Fields (prefer_final_fields)
```dart
// ❌ Mutable field that's never reassigned
class Counter {
  int _count = 0;  // Never reassigned after initialization

  int get count => _count;
}

// ✅ Make it final
class Counter {
  final int _count = 0;

  int get count => _count;
}
```

### Avoid Print (avoid_print)
```dart
// ❌ Using print() in production code
void loadData() {
  print('Loading data...');
  // ...
}

// ✅ Use debugPrint() or logging package
import 'package:flutter/foundation.dart';

void loadData() {
  debugPrint('Loading data...');
  // ...
}
```

### Prefer Single Quotes (prefer_single_quotes)
```dart
// ❌ Using double quotes
final name = "John";
final message = "Hello, World!";

// ✅ Use single quotes
final name = 'John';
final message = 'Hello, World!';
```

### Line Length (formatting)
```dart
// ❌ Line too long (> 80 chars)
final user = User(name: 'John', email: 'john@example.com', address: '123 Main St', phone: '555-1234');

// ✅ Multi-line formatting
final user = User(
  name: 'John',
  email: 'john@example.com',
  address: '123 Main St',
  phone: '555-1234',
);
```

### Missing Trailing Comma (formatting)
```dart
// ❌ No trailing comma
final items = [
  'Apple',
  'Banana',
  'Cherry'
];

// ✅ Add trailing comma for better formatting
final items = [
  'Apple',
  'Banana',
  'Cherry',
];
```
