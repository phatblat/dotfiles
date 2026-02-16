# C++ Validator

Validate C++ code for correctness, style, and build integrity across CMake projects and standalone files.

## Capability

This skill validates C++ codebases using modern C++ tooling: compiler checks, clang-tidy linting, clang-format formatting, cppcheck static analysis, and CMake builds. It supports C++11 through C++23 standards.

## Supported Project Types

- **CMake Projects**: Projects with `CMakeLists.txt`
- **Standalone C++ Files**: Single `.cpp` or `.cc` files
- **Header-Only Libraries**: Projects with only `.h`/`.hpp` files

## Supported Checks

- **compile** - C++ compiler syntax and type checking (g++, clang++)
- **lint** - clang-tidy linting for modernization and best practices
- **format** - clang-format code formatting compliance
- **static** - cppcheck static analysis for bugs and undefined behavior
- **build** - Full CMake build with tests
- **test** - Run unit tests (doctest, Google Test, Catch2)
- **all** - Run all applicable checks

## Usage Protocol

Agents invoke this skill by specifying validation parameters:

```json
{
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "standard": "c++17",
  "compiler": "clang++",
  "buildType": "Debug"
}
```

### Parameters

- **action** (required): Always `"validate"`
- **projectPath** (required): Path to project root (containing CMakeLists.txt or source files)
- **checks** (required): Comma-separated list or `"all"` (e.g., `"lint,format"`, `"compile"`, `"all"`)
- **standard** (optional): C++ standard (`"c++11"`, `"c++14"`, `"c++17"`, `"c++20"`, `"c++23"`, default: `"c++17"`)
- **compiler** (optional): Compiler to use (`"g++"`, `"clang++"`, default: `"clang++"`)
- **buildType** (optional): CMake build type (`"Debug"`, `"Release"`, `"RelWithDebInfo"`, default: `"Debug"`)
- **tidyConfig** (optional): Path to custom `.clang-tidy` config
- **formatConfig** (optional): Path to custom `.clang-format` config

## Output Format

Returns a structured JSON validation report:

```json
{
  "validationReport": {
    "timestamp": "2025-12-14T14:00:00Z",
    "projectType": "cmake",
    "projectPath": "/path/to/project",
    "cppStandard": "c++17",
    "compiler": "clang++",
    "checks": ["compile", "lint", "format", "static", "build"],
    "overallStatus": "failed",
    "summary": {
      "totalIssues": 23,
      "errors": 5,
      "warnings": 18,
      "buildSucceeded": false
    },
    "results": {
      "compile": { ... },
      "lint": { ... },
      "format": { ... },
      "static": { ... },
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
    "duration": "3.2s",
    "compiler": "clang++",
    "standard": "c++17",
    "errors": [
      {
        "file": "src/main.cpp",
        "line": 45,
        "column": 12,
        "severity": "error",
        "message": "use of undeclared identifier 'foo'",
        "code": "undeclared-identifier"
      }
    ],
    "warnings": [
      {
        "file": "src/utils.cpp",
        "line": 23,
        "column": 5,
        "severity": "warning",
        "message": "unused variable 'result'",
        "code": "unused-variable"
      }
    ]
  }
}
```

### Lint Results (clang-tidy)

```json
{
  "lint": {
    "status": "warning",
    "exitCode": 0,
    "duration": "5.1s",
    "configFile": ".clang-tidy",
    "totalIssues": 12,
    "issues": [
      {
        "file": "src/data.cpp",
        "line": 67,
        "column": 3,
        "severity": "warning",
        "message": "use auto when initializing with a cast to avoid duplicating the type name",
        "check": "modernize-use-auto",
        "category": "modernization"
      },
      {
        "file": "include/api.h",
        "line": 34,
        "column": 8,
        "severity": "error",
        "message": "method 'calculate' can be made const",
        "check": "readability-make-member-function-const",
        "category": "readability"
      }
    ]
  }
}
```

### Format Results (clang-format)

```json
{
  "format": {
    "status": "failed",
    "exitCode": 1,
    "duration": "0.9s",
    "configFile": ".clang-format",
    "style": "llvm",
    "formattingIssues": [
      {
        "file": "src/core.cpp",
        "line": 15,
        "issue": "Incorrect indentation (expected 2 spaces, found 4)",
        "fix": "Run: clang-format -i src/core.cpp"
      },
      {
        "file": "include/types.h",
        "line": 28,
        "issue": "Missing space after 'if' keyword",
        "fix": "Run: clang-format -i include/types.h"
      }
    ]
  }
}
```

### Static Analysis Results (cppcheck)

```json
{
  "static": {
    "status": "warning",
    "exitCode": 0,
    "duration": "4.5s",
    "issues": [
      {
        "file": "src/memory.cpp",
        "line": 89,
        "severity": "error",
        "message": "Memory leak: buffer",
        "errorId": "memleak",
        "category": "memory"
      },
      {
        "file": "src/parser.cpp",
        "line": 156,
        "severity": "warning",
        "message": "Array 'data[10]' accessed at index 10, which is out of bounds",
        "errorId": "arrayIndexOutOfBounds",
        "category": "bounds"
      },
      {
        "file": "src/network.cpp",
        "line": 203,
        "severity": "style",
        "message": "Variable 'status' is assigned a value that is never used",
        "errorId": "unreadVariable",
        "category": "style"
      }
    ]
  }
}
```

### Build Results (CMake)

```json
{
  "build": {
    "status": "failed",
    "exitCode": 2,
    "duration": "25.4s",
    "buildType": "Debug",
    "generator": "Unix Makefiles",
    "configureSucceeded": true,
    "buildSucceeded": false,
    "errors": [
      {
        "file": "src/algorithm.cpp",
        "line": 142,
        "message": "undefined reference to 'external_function'",
        "type": "linker-error"
      }
    ],
    "warnings": [
      {
        "message": "CMake Warning: Manually-specified variables were not used by the project: UNUSED_VAR",
        "type": "cmake-warning"
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
    "duration": "8.3s",
    "framework": "doctest",
    "totalTests": 42,
    "passed": 38,
    "failed": 4,
    "skipped": 0,
    "failures": [
      {
        "testSuite": "DataStructures",
        "testCase": "VectorPushBack",
        "file": "test/test_vector.cpp",
        "line": 67,
        "message": "CHECK( vec.size() == 10 ) is NOT correct!\n  values: CHECK( 9 == 10 )"
      }
    ]
  }
}
```

## Common C++ Issues Detected

### Compiler Errors
- **Type Mismatches**: Implicit conversions, incompatible pointer types
- **Undeclared Identifiers**: Missing includes, typos in names
- **Template Errors**: SFINAE failures, incomplete template instantiation
- **Linker Errors**: Undefined references, multiple definitions
- **Memory Issues**: Dangling pointers, use after free (detected by sanitizers)

### clang-tidy Checks (Common)
- **modernize-use-auto**: Use `auto` for iterator types and cast expressions
- **modernize-use-nullptr**: Replace `NULL` and `0` with `nullptr`
- **modernize-use-override**: Mark overriding functions with `override`
- **modernize-make-unique**: Use `std::make_unique` instead of `new`
- **readability-make-member-function-const**: Mark functions that don't modify state as `const`
- **performance-unnecessary-copy-initialization**: Avoid unnecessary copies with `const&`
- **cppcoreguidelines-no-malloc**: Avoid C-style memory management
- **bugprone-use-after-move**: Detect use of moved-from objects

### cppcheck Issues
- **Memory leaks**: Allocated memory never freed
- **Null pointer dereferences**: Dereferencing pointers without null checks
- **Buffer overflows**: Array access out of bounds
- **Uninitialized variables**: Using variables before assignment
- **Resource leaks**: File handles, sockets not closed
- **Dead code**: Unreachable code after return/throw

### clang-format Rules
- **Indentation**: Consistent spacing (2 or 4 spaces)
- **Brace style**: K&R, Allman, or custom
- **Pointer alignment**: `int* ptr` vs `int *ptr`
- **Spacing**: Around operators, after keywords
- **Line breaks**: Function parameters, template arguments

## Project Detection

The skill automatically detects project structure:

1. **CMake Project**: Looks for `CMakeLists.txt` in project root
2. **Single File**: Single `.cpp`, `.cc`, `.cxx`, or `.c++` file
3. **Header-Only**: Only `.h`, `.hpp`, or `.hxx` files present

## Tool Requirements

- **C++ Compiler**: `g++` or `clang++` (part of GCC or LLVM)
- **clang-tidy**: Install via `apt-get install clang-tidy` or `brew install llvm`
- **clang-format**: Install via `apt-get install clang-format` or `brew install clang-format`
- **cppcheck**: Install via `apt-get install cppcheck` or `brew install cppcheck`
- **CMake**: For building projects (install via package manager)
- **doctest**: Header-only test framework (usually included in project)

## Constraints

This skill does NOT:
- Modify or reformat code automatically
- Auto-fix clang-tidy violations
- Apply clang-format changes
- Fix compilation errors
- Resolve linker errors
- Install missing tools or dependencies
- Generate CMake files
- Analyze runtime behavior or crashes

## Error Handling

Returns structured error information for:

- **Missing tools**: Compiler, clang-tidy, cppcheck not installed
- **Invalid project**: No CMakeLists.txt or source files found
- **Build failures**: Compilation errors, linking errors
- **Configuration errors**: Invalid CMake settings, missing dependencies
- **Timeout**: Builds exceeding 15 minutes
- **Tool crashes**: clang-tidy or cppcheck process failures

Example error response:

```json
{
  "error": {
    "type": "missing-tool",
    "message": "clang-tidy not found. Install with: sudo apt-get install clang-tidy",
    "tool": "clang-tidy",
    "installCommand": "sudo apt-get install clang-tidy"
  }
}
```

## Fixing Common Issues

### Use Auto (modernize-use-auto)
```cpp
// ❌ Violates check
std::vector<int>::iterator it = vec.begin();
MyClass* ptr = static_cast<MyClass*>(obj);

// ✅ Use auto
auto it = vec.begin();
auto ptr = static_cast<MyClass*>(obj);
```

### Use nullptr (modernize-use-nullptr)
```cpp
// ❌ Old style
int* ptr = NULL;
void* handle = 0;

// ✅ Modern C++
int* ptr = nullptr;
void* handle = nullptr;
```

### Use override (modernize-use-override)
```cpp
// ❌ Missing override
class Derived : public Base {
    virtual void foo();  // override not specified
};

// ✅ Explicit override
class Derived : public Base {
    void foo() override;
};
```

### Make Member Function Const (readability-make-member-function-const)
```cpp
// ❌ Should be const
class Data {
    int getValue() { return value_; }
    int value_;
};

// ✅ Const correctness
class Data {
    int getValue() const { return value_; }
    int value_;
};
```

### Avoid Unnecessary Copies (performance-unnecessary-copy-initialization)
```cpp
// ❌ Unnecessary copy
void process(std::string data) {
    std::string copy = data;  // Copy not needed
    use(copy);
}

// ✅ Use const reference
void process(const std::string& data) {
    use(data);
}
```

### Use Smart Pointers (cppcoreguidelines-no-malloc)
```cpp
// ❌ C-style memory management
int* data = (int*)malloc(sizeof(int) * 10);
// ... use data ...
free(data);

// ✅ RAII with smart pointers
auto data = std::make_unique<int[]>(10);
// Automatic cleanup
```

### Memory Leak (cppcheck memleak)
```cpp
// ❌ Memory leak
void foo() {
    char* buffer = new char[100];
    // Missing delete[] - memory leaked
}

// ✅ RAII approach
void foo() {
    auto buffer = std::make_unique<char[]>(100);
    // Automatic cleanup
}
```

### Array Bounds (cppcheck arrayIndexOutOfBounds)
```cpp
// ❌ Out of bounds
int data[10];
data[10] = 5;  // Index 10 is out of bounds (valid: 0-9)

// ✅ Proper bounds
int data[10];
data[9] = 5;  // Last valid index

// ✅ Better: use std::vector with bounds checking
std::vector<int> data(10);
data.at(9) = 5;  // Throws if out of bounds
```
