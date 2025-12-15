# Make Executor

Execute GNU Make build operations with structured output and error reporting.

## Capability

This skill executes Make commands for building, testing, installing, and cleaning projects using Makefiles. It returns structured results with exit codes, output, and parsed metadata for Make operations.

## Supported Operations

### Make Commands
- **build** - Build default or specific target
- **clean** - Remove build artifacts
- **install** - Install built artifacts
- **test** - Run tests
- **check** - Alias for test
- **all** - Build all targets
- **distclean** - Remove all generated files
- **custom** - Execute custom target

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "make",
  "command": "build",
  "args": {
    "target": "all",
    "parallel": 8,
    "makefile": "Makefile",
    "directory": ".",
    "variables": {
      "CC": "clang",
      "CFLAGS": "-O2 -Wall"
    }
  }
}
```

### Parameters

- **action** (required): Always `"make"`
- **command** (required): Make command/target to execute
- **args** (required): Command-specific arguments (see below)
- **workdir** (optional): Working directory for command execution
- **timeout** (optional): Timeout in seconds (default: 600s)

### Build Args
```json
{
  "target": "all",
  "parallel": 8,
  "makefile": "Makefile",
  "directory": ".",
  "dryRun": false,
  "keepGoing": false,
  "silent": false,
  "variables": {}
}
```

### Clean Args
```json
{
  "target": "clean",
  "makefile": "Makefile",
  "directory": "."
}
```

### Install Args
```json
{
  "target": "install",
  "makefile": "Makefile",
  "directory": ".",
  "prefix": "/usr/local",
  "destdir": null
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T17:30:00Z",
    "action": "make",
    "command": "build",
    "workdir": "/path/to/project",
    "exitCode": 0,
    "duration": "18.7s",
    "status": "success",
    "stdout": "...",
    "stderr": "...",
    "metadata": {
      "target": "all",
      "parallel": 8,
      "makefile": "Makefile"
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
    "duration": "18.7s",
    "status": "success",
    "metadata": {
      "target": "all",
      "makefile": "Makefile",
      "parallel": 8,
      "buildSteps": 45,
      "artifacts": [
        {
          "type": "executable",
          "name": "myapp",
          "path": "./myapp",
          "size": "1.8 MB"
        },
        {
          "type": "library",
          "name": "libmylib.a",
          "path": "./lib/libmylib.a",
          "size": "890 KB"
        }
      ],
      "warnings": 5,
      "errors": 0
    }
  }
}
```

### Clean Results

```json
{
  "executionReport": {
    "command": "clean",
    "exitCode": 0,
    "duration": "0.8s",
    "status": "success",
    "metadata": {
      "target": "clean",
      "makefile": "Makefile",
      "filesRemoved": [
        "myapp",
        "obj/main.o",
        "obj/utils.o",
        "lib/libmylib.a"
      ],
      "totalFiles": 4
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
    "duration": "1.5s",
    "status": "success",
    "metadata": {
      "target": "install",
      "makefile": "Makefile",
      "prefix": "/usr/local",
      "installedFiles": [
        "/usr/local/bin/myapp",
        "/usr/local/lib/libmylib.a",
        "/usr/local/include/mylib.h"
      ],
      "totalFiles": 3
    }
  }
}
```

### Test Results

```json
{
  "executionReport": {
    "command": "test",
    "exitCode": 0,
    "duration": "5.2s",
    "status": "success",
    "metadata": {
      "target": "test",
      "makefile": "Makefile",
      "totalTests": 15,
      "passed": 15,
      "failed": 0,
      "testOutput": "All tests passed"
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
    "duration": "0.3s",
    "status": "success",
    "metadata": {
      "makefile": "Makefile",
      "targets": [
        {
          "name": "all",
          "type": "phony",
          "description": "Build all targets"
        },
        {
          "name": "clean",
          "type": "phony",
          "description": "Remove build artifacts"
        },
        {
          "name": "install",
          "type": "phony",
          "description": "Install built artifacts"
        },
        {
          "name": "test",
          "type": "phony",
          "description": "Run tests"
        },
        {
          "name": "myapp",
          "type": "file",
          "description": "Main executable"
        }
      ]
    }
  }
}
```

## Common Make Operations

### Build with Parallel Jobs
```json
{
  "action": "make",
  "command": "build",
  "args": {
    "target": "all",
    "parallel": 8
  }
}
```

### Build Specific Target
```json
{
  "action": "make",
  "command": "build",
  "args": {
    "target": "mylib",
    "parallel": 4
  }
}
```

### Dry Run (Show Commands)
```json
{
  "action": "make",
  "command": "build",
  "args": {
    "target": "all",
    "dryRun": true
  }
}
```

### Build with Custom Variables
```json
{
  "action": "make",
  "command": "build",
  "args": {
    "target": "all",
    "variables": {
      "CC": "clang",
      "CFLAGS": "-O3 -march=native",
      "DEBUG": "0"
    }
  }
}
```

### Install to Custom Prefix
```json
{
  "action": "make",
  "command": "install",
  "args": {
    "target": "install",
    "prefix": "/opt/myapp",
    "destdir": "/tmp/staging"
  }
}
```

### Keep Going on Errors
```json
{
  "action": "make",
  "command": "build",
  "args": {
    "target": "all",
    "keepGoing": true,
    "parallel": 8
  }
}
```

## Make Variables

### Common Variables
- **CC**: C compiler (default: cc)
- **CXX**: C++ compiler (default: g++)
- **CFLAGS**: C compiler flags
- **CXXFLAGS**: C++ compiler flags
- **LDFLAGS**: Linker flags
- **PREFIX**: Installation prefix (default: /usr/local)
- **DESTDIR**: Staging directory for installation

### Variable Precedence
1. Command-line variables (highest priority)
2. Environment variables
3. Makefile variables
4. Built-in defaults (lowest priority)

## Tool Requirements

- **GNU Make**: Make 4.0 or later (older versions may work)
- **Compiler**: As specified in Makefile (gcc, clang, etc.)
- **Build Tools**: Linker, archiver, etc.

## Constraints

This skill does NOT:
- Modify Makefiles or source files
- Write or generate Makefile rules
- Install missing build tools
- Configure compilers or toolchains
- Debug Makefile syntax errors
- Analyze build performance
- Interpret compilation errors
- Fix linker errors

## Error Handling

Returns structured error information for:

- **Make not found**: Make not installed or not in PATH
- **Makefile not found**: No Makefile in specified directory
- **Target not found**: Requested target doesn't exist
- **Build failures**: Compilation errors, linker errors
- **Permission errors**: Can't write to install directory
- **Dependency errors**: Missing prerequisites
- **Timeout**: Operations exceeding time limit
- **Circular dependencies**: Makefile has circular rules

Example error response:

```json
{
  "error": {
    "type": "make-not-found",
    "message": "Make not found. Install with package manager",
    "installCommand": "brew install make"
  }
}
```

## Common Make Issues

### Target Not Found
```bash
# Error: make: *** No rule to make target 'foo'
# Solution: Check available targets
make -qp | grep '^[^.#].*:' | cut -d: -f1

# Or if Makefile has help target
make help
```

### Parallel Build Failures
```bash
# Error: Random failures with -j8
# Solution: Some targets not parallel-safe
make -j1  # Serial build

# Or fix Makefile dependencies
```

### Missing Dependencies
```bash
# Error: No rule to make target 'dependency.h'
# Solution: Check file exists or fix Makefile
ls dependency.h
# Or regenerate dependencies
make depend
```

### Permission Denied on Install
```bash
# Error: Permission denied writing to /usr/local
# Solution: Use sudo or DESTDIR
sudo make install
# Or stage to temporary location
make install DESTDIR=/tmp/staging PREFIX=/usr/local
```

### Out of Date Warning
```bash
# Warning: Clock skew detected
# Solution: Touch files or fix system time
find . -type f -exec touch {} +
```

## Best Practices

### Parallel Builds
```json
{
  "parallel": 8  // Or use system CPU count
}
```

### Check Before Building
```json
{
  "dryRun": true  // Show what would be built
}
```

### Verbose Output for Debugging
```json
{
  "variables": {
    "V": "1",  // Verbose mode
    "VERBOSE": "1"
  }
}
```

### Clean Before Full Rebuild
```bash
make clean && make -j8
```

### Install to Staging Directory
```bash
make install DESTDIR=/tmp/staging PREFIX=/usr
```

## Makefile Best Practices

### Required Targets
Every Makefile should have:
- **all**: Default target, builds everything
- **clean**: Removes build artifacts
- **install**: Installs built artifacts
- **test** or **check**: Runs tests

### PHONY Targets
```makefile
.PHONY: all clean install test
```

### Variable Usage
```makefile
CC = gcc
CFLAGS = -Wall -O2
LDFLAGS = -lm

$(CC) $(CFLAGS) -o myapp myapp.c $(LDFLAGS)
```

### Automatic Variables
```makefile
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
# $< = first prerequisite (%.c)
# $@ = target (%.o)
# $^ = all prerequisites
```

### Pattern Rules
```makefile
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
```
