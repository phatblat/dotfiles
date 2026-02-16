# .NET Validator

Validate .NET applications and libraries for correctness, style, and build integrity across C# and F# codebases.

## Capability

This skill validates .NET projects using .NET SDK tools: C#/F# compilation, dotnet format, Roslyn analyzers, msbuild/dotnet build, and test execution. It supports .NET 6+, .NET Framework, and .NET Standard projects.

## Supported Project Types

- **.NET Projects**: Projects with `.csproj` or `.fsproj`
- **Solutions**: Multi-project solutions (`.sln`)
- **.NET MAUI**: Cross-platform UI applications
- **ASP.NET Core**: Web applications and APIs
- **Class Libraries**: Reusable libraries (.dll)
- **Console Applications**: Command-line tools

## Supported Checks

- **compile** - C#/F# compilation (Roslyn compiler)
- **format** - dotnet format code formatting compliance
- **analyze** - Roslyn analyzers and code analysis
- **build** - Full dotnet build or msbuild
- **test** - Unit tests (xUnit, NUnit, MSTest)
- **restore** - NuGet package restoration
- **all** - Run all applicable checks

## Usage Protocol

Agents invoke this skill by specifying validation parameters:

```json
{
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "configuration": "Debug",
  "framework": "net8.0",
  "warningsAsErrors": false
}
```

### Parameters

- **action** (required): Always `"validate"`
- **projectPath** (required): Path to project root (containing .sln, .csproj, or .fsproj)
- **checks** (required): Comma-separated list or `"all"` (e.g., `"format,analyze"`, `"build"`, `"all"`)
- **configuration** (optional): Build configuration (`"Debug"`, `"Release"`, default: `"Debug"`)
- **framework** (optional): Target framework (`"net8.0"`, `"net6.0"`, `"netstandard2.0"`)
- **warningsAsErrors** (optional): Treat warnings as errors (default: `false`)
- **verbosity** (optional): Build verbosity (`"quiet"`, `"minimal"`, `"normal"`, `"detailed"`)

## Output Format

Returns a structured JSON validation report:

```json
{
  "validationReport": {
    "timestamp": "2025-12-14T15:30:00Z",
    "projectType": "dotnet-solution",
    "projectPath": "/path/to/MySolution.sln",
    "configuration": "Debug",
    "framework": "net8.0",
    "checks": ["compile", "format", "analyze", "build", "test"],
    "overallStatus": "warning",
    "summary": {
      "totalIssues": 23,
      "errors": 1,
      "warnings": 22,
      "buildSucceeded": true
    },
    "results": {
      "compile": { ... },
      "format": { ... },
      "analyze": { ... },
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
    "duration": "3.8s",
    "language": "csharp",
    "compiler": "Roslyn",
    "errors": [
      {
        "file": "src/Program.cs",
        "line": 45,
        "column": 12,
        "severity": "error",
        "message": "The name 'Calculate' does not exist in the current context",
        "code": "CS0103"
      }
    ],
    "warnings": [
      {
        "file": "src/Utils.cs",
        "line": 23,
        "column": 9,
        "severity": "warning",
        "message": "The variable 'result' is assigned but its value is never used",
        "code": "CS0219"
      }
    ]
  }
}
```

### Format Results (dotnet format)

```json
{
  "format": {
    "status": "failed",
    "exitCode": 1,
    "duration": "1.5s",
    "totalViolations": 15,
    "editorconfig": ".editorconfig",
    "issues": [
      {
        "file": "src/Controllers/ApiController.cs",
        "line": 28,
        "column": 1,
        "diagnostic": "IDE0055",
        "message": "Fix formatting",
        "severity": "warning"
      },
      {
        "file": "src/Models/User.cs",
        "line": 12,
        "column": 5,
        "diagnostic": "IDE0005",
        "message": "Using directive is unnecessary",
        "severity": "info"
      }
    ]
  }
}
```

### Analyze Results (Roslyn Analyzers)

```json
{
  "analyze": {
    "status": "warning",
    "exitCode": 0,
    "duration": "6.2s",
    "totalIssues": 18,
    "issues": [
      {
        "file": "src/Services/DataService.cs",
        "line": 67,
        "column": 9,
        "severity": "warning",
        "diagnostic": "CA1822",
        "category": "Performance",
        "message": "Member 'GetData' does not access instance data and can be marked as static",
        "helpLink": "https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/ca1822"
      },
      {
        "file": "src/Models/Product.cs",
        "line": 34,
        "column": 16,
        "severity": "warning",
        "diagnostic": "CA1062",
        "category": "Design",
        "message": "Validate parameter 'options' is non-null before using it",
        "helpLink": "https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/ca1062"
      },
      {
        "file": "src/Utilities/StringHelper.cs",
        "line": 15,
        "column": 21,
        "severity": "info",
        "diagnostic": "IDE0046",
        "category": "Style",
        "message": "Use conditional expression for return"
      }
    ]
  }
}
```

### Build Results (dotnet build)

```json
{
  "build": {
    "status": "success",
    "exitCode": 0,
    "duration": "28.4s",
    "configuration": "Debug",
    "framework": "net8.0",
    "runtime": "linux-x64",
    "outputPath": "bin/Debug/net8.0/MyApp.dll",
    "assemblyVersion": "1.0.0.0",
    "fileVersion": "1.0.0.0",
    "warnings": [
      {
        "code": "NU1701",
        "message": "Package 'Newtonsoft.Json 9.0.1' was restored using '.NETFramework,Version=v4.6.1' instead of the project target framework 'net8.0'"
      }
    ]
  }
}
```

### Test Results (xUnit/NUnit/MSTest)

```json
{
  "test": {
    "status": "failed",
    "exitCode": 1,
    "duration": "12.8s",
    "framework": "xunit",
    "totalTests": 52,
    "passed": 48,
    "failed": 4,
    "skipped": 0,
    "failures": [
      {
        "testClass": "MyApp.Tests.CalculatorTests",
        "testMethod": "Divide_ByZero_ThrowsException",
        "message": "Assert.Throws() Failure\nExpected: typeof(System.DivideByZeroException)\nActual:   (No exception was thrown)",
        "stackTrace": "   at MyApp.Tests.CalculatorTests.Divide_ByZero_ThrowsException() in CalculatorTests.cs:line 45"
      }
    ],
    "coverage": {
      "enabled": false
    }
  }
}
```

### Restore Results (NuGet)

```json
{
  "restore": {
    "status": "success",
    "exitCode": 0,
    "duration": "5.3s",
    "packagesRestored": 47,
    "issues": []
  }
}
```

## Common .NET Issues Detected

### Compiler Errors
- **CS0103**: Name does not exist in current context
- **CS0246**: Type or namespace name not found
- **CS0029**: Cannot implicitly convert type
- **CS0161**: Not all code paths return a value
- **CS1061**: Type does not contain definition for member
- **CS8600-CS8625**: Nullable reference type warnings

### Code Analysis (Roslyn Analyzers)
- **CA1822**: Member can be marked as static
- **CA1062**: Validate parameter is non-null
- **CA1031**: Do not catch general exception types
- **CA1508**: Avoid dead conditional code
- **CA2007**: Do not directly await a Task without ConfigureAwait
- **IDE0055**: Fix formatting
- **IDE0005**: Remove unnecessary using directives
- **IDE0046**: Use conditional expression

### Format Issues (dotnet format)
- **IDE0055**: Incorrect indentation, spacing, or brace placement
- **IDE0005**: Unnecessary using directives
- **IDE0161**: Use file-scoped namespace
- **IDE0090**: Use 'new(...)' instead of 'new Type(...)'

### Build Issues
- **NU1701**: Package compatibility warnings
- **MSB3277**: Assembly conflicts between different versions
- **CS1703**: Multiple assemblies with same identity
- **TargetFramework mismatch**: Project references incompatible frameworks

## Project Detection

The skill automatically detects .NET project structure:

1. **Solution Files**: Looks for `*.sln` files
2. **Project Files**: Identifies `*.csproj` or `*.fsproj`
3. **Framework**: Reads `<TargetFramework>` from project files
4. **Project Type**: Detects console app, web app, library, MAUI, etc.

## Tool Requirements

- **.NET SDK**: .NET 6.0 or later (install from dotnet.microsoft.com)
- **dotnet CLI**: Part of .NET SDK
- **Roslyn Analyzers**: Included with .NET SDK
- **dotnet format**: Part of .NET SDK
- **Test Frameworks**: xUnit, NUnit, or MSTest (project dependencies)

## Constraints

This skill does NOT:
- Modify or reformat code automatically
- Auto-fix analyzer violations
- Apply dotnet format changes
- Fix compilation errors
- Resolve NuGet package conflicts
- Install missing .NET SDKs or runtimes
- Generate missing project files
- Analyze runtime behavior or crashes
- Run integration tests requiring external services

## Error Handling

Returns structured error information for:

- **Missing .NET SDK**: dotnet command not found
- **Invalid project**: No .sln or .csproj files found
- **Build failures**: Compilation errors, missing dependencies
- **Configuration errors**: Invalid target framework, missing runtime
- **Timeout**: Builds exceeding 15 minutes
- **Tool crashes**: dotnet CLI failures, out of memory errors

Example error response:

```json
{
  "error": {
    "type": "missing-dotnet-sdk",
    "message": ".NET SDK not found. Install from https://dotnet.microsoft.com/download",
    "requiredVersion": "8.0",
    "installCommand": "Download from https://dotnet.microsoft.com/download"
  }
}
```

## Fixing Common Issues

### Name Does Not Exist (CS0103)
```csharp
// ❌ Missing using directive
var json = JsonConvert.SerializeObject(data);

// ✅ Add using
using Newtonsoft.Json;
var json = JsonConvert.SerializeObject(data);
```

### Member Can Be Static (CA1822)
```csharp
// ❌ Violates analyzer rule
public class DataService
{
    public string GetData() => "data";  // Doesn't use instance state
}

// ✅ Make static
public class DataService
{
    public static string GetData() => "data";
}
```

### Validate Parameter Non-Null (CA1062)
```csharp
// ❌ No null check
public void Process(string input)
{
    var result = input.ToUpper();  // Could throw NullReferenceException
}

// ✅ Validate parameter
public void Process(string input)
{
    ArgumentNullException.ThrowIfNull(input);
    var result = input.ToUpper();
}
```

### Remove Unnecessary Using (IDE0005)
```csharp
// ❌ Unused using directive
using System.Linq;
using System.Collections.Generic;

namespace MyApp
{
    public class Program { }  // Doesn't use either namespace
}

// ✅ Remove unused
namespace MyApp
{
    public class Program { }
}
```

### Use File-Scoped Namespace (IDE0161)
```csharp
// ❌ Traditional namespace
namespace MyApp
{
    public class Program
    {
        // ...
    }
}

// ✅ File-scoped namespace (C# 10+)
namespace MyApp;

public class Program
{
    // ...
}
```

### ConfigureAwait in Library Code (CA2007)
```csharp
// ❌ Missing ConfigureAwait in library code
public async Task<string> GetDataAsync()
{
    var result = await httpClient.GetStringAsync(url);
    return result;
}

// ✅ Use ConfigureAwait(false) in libraries
public async Task<string> GetDataAsync()
{
    var result = await httpClient.GetStringAsync(url).ConfigureAwait(false);
    return result;
}
```
