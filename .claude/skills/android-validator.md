# Android Validator

Validate Android applications for correctness, style, and build integrity across Kotlin and Java codebases.

## Capability

This skill validates Android projects using Android SDK tools: Kotlin/Java compilation, Android Lint, ktlint formatting, Gradle builds, and test execution. It supports both pure Android apps and apps with native JNI/NDK components.

## Supported Project Types

- **Gradle-based Android Projects**: Projects with `build.gradle` or `build.gradle.kts`
- **Android App Modules**: Application modules with `AndroidManifest.xml`
- **Android Library Modules**: Library modules (AAR)
- **Android Projects with NDK/JNI**: Native C/C++ integration

## Supported Checks

- **compile** - Kotlin/Java compilation (kotlinc, javac)
- **lint** - Android Lint analysis for Android-specific issues
- **format** - ktlint Kotlin code formatting compliance
- **build** - Full Gradle build (assembleDebug/assembleRelease)
- **test** - Unit tests (JUnit) and instrumentation tests
- **ndk** - NDK/JNI native code compilation
- **all** - Run all applicable checks

## Usage Protocol

Agents invoke this skill by specifying validation parameters:

```json
{
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "module": "app",
  "buildVariant": "debug",
  "includeNdk": true
}
```

### Parameters

- **action** (required): Always `"validate"`
- **projectPath** (required): Path to Android project root (containing build.gradle)
- **checks** (required): Comma-separated list or `"all"` (e.g., `"lint,format"`, `"build"`, `"all"`)
- **module** (optional): Module name to validate (default: `"app"`)
- **buildVariant** (optional): Build variant (`"debug"`, `"release"`, default: `"debug"`)
- **includeNdk** (optional): Include NDK/JNI validation (default: `false`)
- **minSdk** (optional): Minimum Android API level for lint checks
- **targetSdk** (optional): Target Android API level for lint checks

## Output Format

Returns a structured JSON validation report:

```json
{
  "validationReport": {
    "timestamp": "2025-12-14T15:00:00Z",
    "projectType": "android-gradle",
    "projectPath": "/path/to/android-project",
    "module": "app",
    "buildVariant": "debug",
    "checks": ["compile", "lint", "format", "build", "test"],
    "overallStatus": "warning",
    "summary": {
      "totalIssues": 15,
      "errors": 2,
      "warnings": 13,
      "buildSucceeded": true
    },
    "results": {
      "compile": { ... },
      "lint": { ... },
      "format": { ... },
      "build": { ... },
      "test": { ... }
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
    "duration": "4.5s",
    "language": "kotlin",
    "errors": [
      {
        "file": "app/src/main/java/com/example/MainActivity.kt",
        "line": 45,
        "column": 12,
        "severity": "error",
        "message": "Unresolved reference: viewModel",
        "code": "UNRESOLVED_REFERENCE"
      }
    ],
    "warnings": [
      {
        "file": "app/src/main/java/com/example/Utils.kt",
        "line": 23,
        "column": 5,
        "severity": "warning",
        "message": "Variable 'result' is never used",
        "code": "UNUSED_VARIABLE"
      }
    ]
  }
}
```

### Lint Results (Android Lint)

```json
{
  "lint": {
    "status": "warning",
    "exitCode": 0,
    "duration": "8.2s",
    "reportFile": "app/build/reports/lint-results-debug.xml",
    "totalIssues": 18,
    "issues": [
      {
        "id": "HardcodedText",
        "severity": "warning",
        "message": "Hardcoded string \"Hello\", should use @string resource",
        "category": "Internationalization",
        "priority": 5,
        "file": "app/src/main/res/layout/activity_main.xml",
        "line": 15
      },
      {
        "id": "ObsoleteSdkInt",
        "severity": "warning",
        "message": "Unnecessary SDK version check (minSdkVersion is 24)",
        "category": "Performance",
        "priority": 6,
        "file": "app/src/main/java/com/example/MainActivity.kt",
        "line": 67
      },
      {
        "id": "MissingPermission",
        "severity": "error",
        "message": "Missing permissions required by LocationManager.requestLocationUpdates: android.permission.ACCESS_FINE_LOCATION or android.permission.ACCESS_COARSE_LOCATION",
        "category": "Correctness",
        "priority": 9,
        "file": "app/src/main/java/com/example/LocationService.kt",
        "line": 34
      }
    ]
  }
}
```

### Format Results (ktlint)

```json
{
  "format": {
    "status": "failed",
    "exitCode": 1,
    "duration": "1.3s",
    "totalViolations": 12,
    "issues": [
      {
        "file": "app/src/main/java/com/example/ViewModel.kt",
        "line": 25,
        "column": 1,
        "rule": "indent",
        "message": "Unexpected indentation (4) (should be 8)"
      },
      {
        "file": "app/src/main/java/com/example/Repository.kt",
        "line": 48,
        "column": 80,
        "rule": "max-line-length",
        "message": "Exceeded max line length (80)"
      },
      {
        "file": "app/src/main/java/com/example/Model.kt",
        "line": 12,
        "column": 1,
        "rule": "import-ordering",
        "message": "Imports must be ordered in lexicographic order without any empty lines in-between"
      }
    ]
  }
}
```

### Build Results (Gradle)

```json
{
  "build": {
    "status": "success",
    "exitCode": 0,
    "duration": "45.8s",
    "task": "assembleDebug",
    "buildType": "debug",
    "apkPath": "app/build/outputs/apk/debug/app-debug.apk",
    "apkSize": "12.4 MB",
    "minSdk": 24,
    "targetSdk": 34,
    "versionCode": 1,
    "versionName": "1.0",
    "warnings": [
      {
        "message": "The specified Android SDK Build Tools version (30.0.3) is ignored, as it is below the minimum supported version (34.0.0)"
      }
    ]
  }
}
```

### Test Results

```json
{
  "test": {
    "status": "failed",
    "exitCode": 1,
    "duration": "15.7s",
    "totalTests": 48,
    "passed": 45,
    "failed": 3,
    "skipped": 0,
    "testType": "unit",
    "failures": [
      {
        "testClass": "com.example.ViewModelTest",
        "testMethod": "testDataLoading",
        "message": "Expected: <5>\n     but: was <3>",
        "stackTrace": "org.junit.ComparisonFailure: Expected: <5>\n     but: was <3>\n\tat com.example.ViewModelTest.testDataLoading(ViewModelTest.kt:42)"
      }
    ]
  }
}
```

### NDK/JNI Results

```json
{
  "ndk": {
    "status": "success",
    "exitCode": 0,
    "duration": "12.3s",
    "abis": ["arm64-v8a", "armeabi-v7a", "x86_64"],
    "nativeLibraries": [
      {
        "name": "libnative-lib.so",
        "abi": "arm64-v8a",
        "size": "245 KB"
      }
    ],
    "jniIssues": []
  }
}
```

## Common Android Issues Detected

### Compiler Errors
- **Unresolved References**: Missing imports, typos in class/function names
- **Type Mismatches**: Incorrect null safety, wrong parameter types
- **Missing Dependencies**: Gradle dependencies not declared
- **Syntax Errors**: Kotlin/Java syntax violations

### Android Lint Issues (Common)
- **HardcodedText**: Strings not in resources (i18n issue)
- **MissingPermission**: Required permissions not in manifest
- **ObsoleteSdkInt**: Unnecessary API level checks
- **UnusedResources**: Unused layouts, drawables, strings
- **Overdraw**: Excessive view hierarchy depth
- **IconDensities**: Missing drawable densities (mdpi, hdpi, xhdpi, etc.)
- **ContentDescription**: Missing accessibility descriptions
- **SetTextI18n**: Setting text with string concatenation instead of resources

### ktlint Rules
- **indent**: Consistent 4-space indentation
- **max-line-length**: Lines under 120 characters
- **import-ordering**: Alphabetical imports, standard library first
- **no-wildcard-imports**: Explicit imports instead of wildcards
- **trailing-comma**: Trailing commas in multi-line lists
- **chain-wrapping**: Proper line breaks in call chains

### Build Issues
- **Duplicate Classes**: Same class in multiple dependencies
- **Version Conflicts**: Incompatible dependency versions
- **ProGuard Errors**: Obfuscation issues in release builds
- **Manifest Merge Conflicts**: Conflicting manifest entries
- **Resource Conflicts**: Duplicate resource IDs

## Project Detection

The skill automatically detects Android project structure:

1. **Gradle Build Files**: Looks for `build.gradle` or `build.gradle.kts`
2. **Android Manifest**: Verifies `AndroidManifest.xml` exists
3. **Module Structure**: Identifies app vs library modules
4. **NDK Integration**: Checks for `CMakeLists.txt` or `Android.mk` in jni/cpp folders

## Tool Requirements

- **Android SDK**: Android SDK with build-tools and platform-tools
- **Gradle**: Gradle wrapper (`./gradlew`) or system Gradle
- **Java/Kotlin**: JDK 17+ and Kotlin compiler
- **Android Lint**: Part of Android SDK build-tools
- **ktlint**: Install via `brew install ktlint` or Gradle plugin
- **Android NDK** (optional): For native code validation

## Constraints

This skill does NOT:
- Modify or reformat code automatically
- Auto-fix Android Lint violations
- Apply ktlint formatting changes
- Fix compilation errors
- Resolve dependency conflicts
- Install missing SDK components
- Generate missing resources
- Analyze runtime behavior or crashes
- Run instrumentation tests on devices/emulators

## Error Handling

Returns structured error information for:

- **Missing Android SDK**: ANDROID_HOME not set
- **Invalid project**: No build.gradle or AndroidManifest.xml found
- **Build failures**: Compilation errors, dependency resolution failures
- **Configuration errors**: Invalid build variants, missing modules
- **Timeout**: Builds exceeding 15 minutes
- **Tool crashes**: Gradle daemon crashes, out of memory errors

Example error response:

```json
{
  "error": {
    "type": "missing-android-sdk",
    "message": "Android SDK not found. Set ANDROID_HOME environment variable",
    "solution": "export ANDROID_HOME=/path/to/android/sdk"
  }
}
```

## Fixing Common Issues

### Hardcoded Text (HardcodedText)
```kotlin
// ❌ Violates lint rule
Text("Hello World")

// ✅ Use string resource
Text(stringResource(R.string.hello_world))
```

### Missing Permission (MissingPermission)
```xml
<!-- AndroidManifest.xml -->
<!-- Add required permission -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Unresolved Reference
```kotlin
// ❌ Missing import
val viewModel = MyViewModel()

// ✅ Add import
import com.example.MyViewModel
val viewModel = MyViewModel()
```

### Import Ordering (import-ordering)
```kotlin
// ❌ Wrong order
import com.example.MyClass
import android.os.Bundle
import java.util.List

// ✅ Correct order (stdlib, android, third-party, app)
import java.util.List
import android.os.Bundle
import com.example.MyClass
```

### Max Line Length (max-line-length)
```kotlin
// ❌ Too long
val result = someVeryLongFunctionName(parameter1, parameter2, parameter3, parameter4, parameter5)

// ✅ Multi-line
val result = someVeryLongFunctionName(
    parameter1,
    parameter2,
    parameter3,
    parameter4,
    parameter5
)
```
