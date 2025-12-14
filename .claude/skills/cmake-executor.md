# CMake Executor

Execute CMake build system operations with structured output and error reporting.

## Capability

This skill executes CMake commands for configuring, building, testing, and installing C/C++ projects. It returns structured results with exit codes, output, and parsed metadata for CMake operations.

## Supported Operations

### CMake Commands
- **configure** - Configure project (cmake)
- **build** - Build targets (cmake --build)
- **test** - Run tests (ctest)
- **install** - Install built artifacts (cmake --install)
- **clean** - Clean build directory
- **reconfigure** - Reconfigure with different options
- **list-targets** - List available build targets
- **list-tests** - List available tests

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "cmake",
  "command": "configure",
  "args": {
    "sourceDir": ".",
    "buildDir": "build",
    "generator": "Ninja",
    "buildType": "Release",
    "options": {
      "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
    }
  }
}
```

### Parameters

- **action** (required): Always `"cmake"`
- **command** (required): CMake command to execute
- **args** (required): Command-specific arguments (see below)
- **workdir** (optional): Working directory for command execution
- **timeout** (optional): Timeout in seconds (default: 600s)

### Configure Args
```json
{
  "sourceDir": ".",
  "buildDir": "build",
  "generator": "Ninja",
  "buildType": "Release",
  "options": {
    "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
    "CMAKE_CXX_STANDARD": "17",
    "BUILD_TESTING": "ON"
  },
  "toolchainFile": null,
  "installPrefix": "/usr/local"
}
```

### Build Args
```json
{
  "buildDir": "build",
  "target": "all",
  "parallel": 8,
  "verbose": false,
  "config": "Release"
}
```

### Test Args
```json
{
  "buildDir": "build",
  "parallel": 4,
  "verbose": false,
  "outputOnFailure": true,
  "testFilter": null
}
```

### Install Args
```json
{
  "buildDir": "build",
  "prefix": "/usr/local",
  "config": "Release",
  "component": null
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T17:00:00Z",
    "action": "cmake",
    "command": "build",
    "workdir": "/path/to/project",
    "exitCode": 0,
    "duration": "25.4s",
    "status": "success",
    "stdout": "...",
    "stderr": "...",
    "metadata": {
      "targets": ["app", "lib"],
      "buildType": "Release",
      "generator": "Ninja"
    }
  }
}
```

### Configure Results

```json
{
  "executionReport": {
    "command": "configure",
    "exitCode": 0,
    "duration": "3.2s",
    "status": "success",
    "metadata": {
      "generator": "Ninja",
      "buildType": "Release",
      "sourceDir": "/path/to/source",
      "buildDir": "/path/to/build",
      "cmakeVersion": "3.28.1",
      "compilers": {
        "CXX": "/usr/bin/clang++",
        "C": "/usr/bin/clang"
      },
      "options": {
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
        "CMAKE_CXX_STANDARD": "17"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_INSTALL_PREFIX": "/usr/local"
      }
    }
  }
}
```

### Build Results

```json
{
  "executionReport": {
    "command": "build",
    "exitCode": 0,
    "duration": "45.8s",
    "status": "success",
    "metadata": {
      "buildDir": "/path/to/build",
      "target": "all",
      "config": "Release",
      "parallel": 8,
      "buildSteps": 156,
      "successfulSteps": 156,
      "failedSteps": 0,
      "artifacts": [
        {
          "type": "executable",
          "name": "myapp",
          "path": "build/myapp",
          "size": "2.4 MB"
        },
        {
          "type": "library",
          "name": "libmylib.a",
          "path": "build/lib/libmylib.a",
          "size": "1.1 MB"
        }
      ],
      "warnings": 3,
      "errors": 0
    }
  }
}
```

### Test Results (CTest)

```json
{
  "executionReport": {
    "command": "test",
    "exitCode": 0,
    "duration": "8.5s",
    "status": "success",
    "metadata": {
      "buildDir": "/path/to/build",
      "totalTests": 42,
      "passed": 42,
      "failed": 0,
      "skipped": 0,
      "timeout": 0,
      "tests": [
        {
          "name": "test_algorithm",
          "status": "passed",
          "duration": "0.5s"
        },
        {
          "name": "test_data_structure",
          "status": "passed",
          "duration": "0.3s"
        }
      ]
    }
  }
}
```

### Install Results

```json
{
  "executionReport": {
    "command": "install",
    "exitCode": 0,
    "duration": "2.1s",
    "status": "success",
    "metadata": {
      "buildDir": "/path/to/build",
      "installPrefix": "/usr/local",
      "config": "Release",
      "installedFiles": [
        "/usr/local/bin/myapp",
        "/usr/local/lib/libmylib.a",
        "/usr/local/include/mylib.hpp"
      ],
      "totalFiles": 3
    }
  }
}
```

### List Targets Results

```json
{
  "executionReport": {
    "command": "list-targets",
    "exitCode": 0,
    "duration": "0.5s",
    "status": "success",
    "metadata": {
      "buildDir": "/path/to/build",
      "targets": [
        {
          "name": "all",
          "type": "utility",
          "description": "Build all targets"
        },
        {
          "name": "myapp",
          "type": "executable",
          "description": "Main application"
        },
        {
          "name": "mylib",
          "type": "static_library",
          "description": "Core library"
        },
        {
          "name": "clean",
          "type": "utility",
          "description": "Remove build artifacts"
        }
      ]
    }
  }
}
```

## Common CMake Operations

### Configure with Custom Options
```json
{
  "action": "cmake",
  "command": "configure",
  "args": {
    "sourceDir": ".",
    "buildDir": "build",
    "generator": "Ninja",
    "buildType": "Debug",
    "options": {
      "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
      "CMAKE_CXX_STANDARD": "20",
      "BUILD_SHARED_LIBS": "ON",
      "CMAKE_VERBOSE_MAKEFILE": "ON"
    }
  }
}
```

### Build Specific Target
```json
{
  "action": "cmake",
  "command": "build",
  "args": {
    "buildDir": "build",
    "target": "mylib",
    "parallel": 8,
    "verbose": true
  }
}
```

### Run Specific Tests
```json
{
  "action": "cmake",
  "command": "test",
  "args": {
    "buildDir": "build",
    "testFilter": "test_algorithm",
    "verbose": true,
    "outputOnFailure": true
  }
}
```

### Install to Custom Prefix
```json
{
  "action": "cmake",
  "command": "install",
  "args": {
    "buildDir": "build",
    "prefix": "/opt/myapp",
    "config": "Release"
  }
}
```

## Supported Generators

- **Unix Makefiles**: Traditional make-based builds
- **Ninja**: Fast parallel builds (recommended)
- **Xcode**: macOS/iOS development
- **Visual Studio**: Windows development
- **Ninja Multi-Config**: Multi-configuration Ninja builds

## Tool Requirements

- **CMake**: CMake 3.14 or later
- **Build Tools**: Corresponding to generator (make, ninja, xcodebuild, msbuild)
- **Compiler**: C/C++ compiler (gcc, clang, msvc)
- **CTest**: Part of CMake (for testing)

## Constraints

This skill does NOT:
- Modify CMakeLists.txt or source files
- Write or generate CMake configuration files
- Install missing dependencies
- Configure compilers or toolchains
- Debug CMake cache issues
- Analyze build performance
- Interpret test failures
- Fix compilation errors

## Error Handling

Returns structured error information for:

- **CMake not found**: CMake not installed or not in PATH
- **Invalid source directory**: No CMakeLists.txt found
- **Configuration failures**: Missing dependencies, incompatible options
- **Build failures**: Compilation errors, linker errors
- **Test failures**: Failed tests with output
- **Install failures**: Permission errors, missing targets
- **Timeout**: Operations exceeding time limit
- **Generator not available**: Requested generator not found

Example error response:

```json
{
  "error": {
    "type": "cmake-not-found",
    "message": "CMake not found. Install from https://cmake.org/download/",
    "installCommand": "brew install cmake"
  }
}
```

## Common CMake Issues

### Generator Not Available
```bash
# Error: Could not create named generator "Ninja"
# Solution: Install Ninja
brew install ninja
# Or specify different generator
cmake -G "Unix Makefiles" ..
```

### Missing Dependencies
```bash
# Error: Could not find Boost
# Solution: Install dependency or specify path
cmake -DBoost_ROOT=/path/to/boost ..
```

### Cache Issues
```bash
# Error: CMake cache problems
# Solution: Remove cache and reconfigure
rm -rf build/CMakeCache.txt build/CMakeFiles
cmake -B build -S .
```

### Compiler Not Found
```bash
# Error: CMAKE_CXX_COMPILER not found
# Solution: Specify compiler explicitly
cmake -DCMAKE_CXX_COMPILER=/usr/bin/clang++ ..
```

### Out-of-Source Build Required
```bash
# Error: In-source builds not recommended
# Solution: Use separate build directory
mkdir build && cd build
cmake ..
```

## Best Practices

### Recommended Configure Options
```json
{
  "options": {
    "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
    "CMAKE_COLOR_DIAGNOSTICS": "ON",
    "CMAKE_BUILD_TYPE": "Release",
    "BUILD_TESTING": "ON"
  }
}
```

### Parallel Builds
```json
{
  "parallel": 8  // Or use system CPU count
}
```

### Verbose Output for Debugging
```json
{
  "verbose": true,
  "options": {
    "CMAKE_VERBOSE_MAKEFILE": "ON"
  }
}
```

### Clean Build
```bash
# Complete clean: Remove build directory
rm -rf build && cmake -B build -S .

# Or use CMake clean
cmake --build build --target clean
```
