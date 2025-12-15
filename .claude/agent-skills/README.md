# Agent Skills Library

Reusable capability modules that agents can invoke to perform specific tasks.

## Skills Registry

### Tools

#### `test-runner`
**Path**: `~/.claude/skills/test-runner.md`

**Purpose**: Execute test suites and report results

**Supported Frameworks**: Make, npm, pytest, cargo, go test, gradle, maven, dotnet, rake/rspec

**What It Does**:
- Detects appropriate test command based on project structure
- Executes tests and captures output
- Returns exit code, stdout, stderr, duration
- Does NOT analyze failures or suggest fixes

**Used By**: `implementor`, `project-planner`, any testing agent

**Example Invocation**:
```
[invoke test-runner]
input: {
  "action": "run-tests",
  "testFramework": "auto"
}
```

---

#### `code-browser`
**Path**: `~/.claude/skills/code-browser.md`

**Purpose**: Search and locate code in a codebase

**Search Types**: implementation, usage, pattern, concept, inheritance

**What It Does**:
- Searches for code matching specific criteria
- Groups results by relevance (primary implementations vs. usage)
- Returns file paths, line numbers, code snippets
- Does NOT analyze or interpret findings

**Used By**: `implementor`, `research-agent`, `code-analyzer`, architecture agents

**Example Invocation**:
```
[invoke code-browser]
input: {
  "action": "search",
  "query": "payment processing",
  "searchType": "concept"
}
```

---

#### `shell-validator`
**Path**: `~/.claude/skills/shell-validator.md`

**Purpose**: Validate shell scripts for correctness, portability, and best practices

**Validation Types**: syntax, portability, best-practices, security, formatting

**What It Does**:
- Runs shellcheck to detect syntax and logic errors
- Checks for macOS vs Linux portability issues
- Validates against best practices and security standards
- Returns structured issues with locations and suggestions
- Does NOT modify or rewrite scripts

**Used By**: `shell-expert`, script-reviewer, automation-developer

**Example Invocation**:
```
[invoke shell-validator]
input: {
  "action": "validate",
  "scriptPath": "deploy.sh",
  "checks": "all",
  "targetPlatforms": ["macos", "linux"]
}
```

---

#### `rust-validator`
**Path**: `~/.claude/skills/rust-validator.md`

**Purpose**: Validate Rust code for correctness, style, and performance

**Validation Types**: compile, clippy, formatting, dependency audit

**What It Does**:
- Compiles the project to catch errors (cargo build)
- Runs clippy to detect performance and style issues
- Checks formatting compliance (cargo fmt)
- Audits dependencies for vulnerabilities (cargo audit)
- Returns structured issues with locations and suggestions
- Does NOT modify code or auto-format

**Used By**: `rust-expert`, code-reviewer, performance-optimizer

**Example Invocation**:
```
[invoke rust-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "toolchain": "stable"
}
```

---

#### `doc-extractor`
**Path**: `~/.claude/skills/doc-extractor.md`

**Purpose**: Extract documentation-relevant information from source code

**Extraction Types**: comments, structure, examples, undocumented, all

**What It Does**:
- Extracts documentation comments and docstrings
- Parses code structure and public APIs
- Identifies undocumented code items
- Extracts and validates code examples
- Suggests documentation structure
- Returns structured extraction data
- Does NOT generate documentation

**Used By**: `tech-writer`, documentation-reviewer, api-designer

**Example Invocation**:
```
[invoke doc-extractor]
input: {
  "action": "extract",
  "sourcePath": "src/lib.rs",
  "language": "rust",
  "extractTypes": "all"
}
```

---

#### `python-validator`
**Path**: `~/.claude/skills/python-validator.md`

**Purpose**: Validate Python code for style, types, and security

**Validation Types**: format, lint, types, security, dependencies

**What It Does**:
- Checks formatting with Black/PEP 8
- Runs Pylint/Ruff for code quality
- Validates type hints with mypy
- Detects security issues with bandit
- Checks for vulnerable/outdated dependencies
- Returns structured issues with locations and suggestions
- Does NOT modify code or auto-format

**Used By**: `python-expert`, code-reviewer, security-auditor

**Example Invocation**:
```
[invoke python-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "pythonVersion": "3.13"
}
```

---

#### `format-converter`
**Path**: `~/.claude/skills/format-converter.md`

**Purpose**: Convert data between different structured and semi-structured formats

---

#### `ditto-docs-search`
**Path**: `~/.claude/skills/ditto-docs-search.md`

**Purpose**: Search Ditto SDK documentation and retrieve API references, guides, and examples

**Supported Search Types**: general, api, guide, example, dql

**What It Does**:
- Searches docs.ditto.live for Ditto documentation
- Returns documentation pages with URLs and excerpts
- Supports platform-specific filtering (Swift, JS, Rust, C++, Java, Kotlin, Flutter, C#)
- Includes SDK version selection (latest, v4, v5-preview)
- Detects broken links and outdated content warnings
- Does NOT modify documentation

**Used By**: `ditto-docs`, ditto-sdk-architect, tech-writer, documentation-reviewer

**Example Invocation**:
```
[invoke ditto-docs-search]
input: {
  "action": "search",
  "query": "how to set up sync",
  "searchType": "guide"
}
```

---

#### `dql-validator`
**Path**: `~/.claude/skills/dql-validator.md`

**Purpose**: Validate Ditto Query Language (DQL) queries for syntax, compatibility, and optimization

**Validation Types**: syntax, compatibility, optimization, all

**What It Does**:
- Validates DQL query syntax against language rules
- Checks compatibility with DQL feature set
- Suggests performance optimizations
- Detects legacy query builder patterns
- Returns validation report with issues and suggestions
- Does NOT modify queries

**Used By**: `dql-expert`, ditto-sdk-architect, implementor

**Example Invocation**:
```
[invoke dql-validator]
input: {
  "action": "validate",
  "query": "SELECT * FROM users WHERE age > 18",
  "validateFor": "all"
}
```

---

#### `linear-searcher`
**Path**: `~/.claude/skills/linear-searcher.md`

**Purpose**: Search Linear issues with relationships to pull requests, tickets, and logs

**Search Categories**: content, assignee, label, status, cycle

**What It Does**:
- Searches Linear issues by multiple criteria
- Returns matched issues with metadata and relationships
- Retrieves linked PRs, Zendesk tickets, parent/child issues
- Supports filtering by project, team, cycle, status
- Handles issue dependencies and cross-references
- Does NOT modify issues

**Used By**: `linear-expert`, project-planner, implementor

**Example Invocation**:
```
[invoke linear-searcher]
input: {
  "action": "search",
  "query": "authentication",
  "searchBy": "content",
  "includeLinks": true
}
```

---

#### `notion-searcher`
**Path**: `~/.claude/skills/notion-searcher.md`

**Purpose**: Search Notion workspace for pages, databases, and documentation

**Search Types**: all, pages, databases, title, tags, content

**What It Does**:
- Searches Notion for pages and database entries
- Returns matched content with metadata and hierarchy
- Supports filtering by workspace, database, tag, status
- Includes page relationships (parent/child)
- Provides content previews (optional)
- Does NOT create or modify pages

**Used By**: `notion-expert`, tech-writer, project-planner

**Example Invocation**:
```
[invoke notion-searcher]
input: {
  "action": "search",
  "query": "meeting notes",
  "searchIn": "pages",
  "includeContent": true
}
```

---

#### `git-executor`
**Path**: `~/.claude/skills/git-executor.md`

**Purpose**: Execute git commands and return structured results with safety checks

**Supported Commands**: commit, branch, checkout, merge, rebase, push, pull, fetch, log, diff, status, stash, reset

**What It Does**:
- Executes git commands with timeout protection
- Returns exit code, stdout, stderr, execution time
- Parses output for metadata
- Enforces safety checks (prevents main commits, unsafe force-push)
- Detects merge conflicts and destructive operations
- Does NOT interpret results

**Used By**: `github-expert`, implementor, project-planner

**Example Invocation**:
```
[invoke git-executor]
input: {
  "action": "execute",
  "command": "commit",
  "args": ["-m", "feat: new feature"]
}
```

---

#### `slack-searcher`
**Path**: `~/.claude/skills/slack-searcher.md`

**Purpose**: Search and retrieve messages, files, and conversations from Slack workspaces

**Search Types**: messages, files, threads, all

**What It Does**:
- Searches Slack messages by keywords, users, channels, date ranges
- Retrieves files by filename or metadata
- Fetches threaded conversations with full reply context
- Returns matched results with metadata and attachments
- Includes message reactions and thread information
- Does NOT create, edit, or delete messages

**Used By**: `slack-expert`, team-analyst, knowledge-base-assistant

**Example Invocation**:
```
[invoke slack-searcher]
input: {
  "action": "search",
  "query": "deployment",
  "filters": {"channel": "engineering"},
  "includeThreads": true
}
```

---

#### `go-validator`
**Path**: `~/.claude/skills/go-validator.md`

**Purpose**: Validate Go projects for correctness, style, and dependency health

**Validation Types**: compile, lint, format, deps, test, all

**What It Does**:
- Compiles projects using `go build` to detect errors
- Runs `go vet` and `golangci-lint` for code quality
- Checks formatting with `gofmt`
- Validates dependencies with `go mod`
- Runs tests and reports coverage
- Returns structured issues with line-specific locations

**Used By**: `go-expert`, code-reviewer, performance-optimizer

**Example Invocation**:
```
[invoke go-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "goVersion": "1.21"
}
```

---

#### `js-validator`
**Path**: `~/.claude/skills/js-validator.md`

**Purpose**: Validate JavaScript and TypeScript projects for code quality, style, and type correctness

**Validation Types**: lint, format, types, deps, test, all

**What It Does**:
- Runs ESLint to detect code quality issues
- Checks formatting with Prettier
- Validates types using TypeScript compiler (tsc)
- Audits dependencies for security vulnerabilities (npm audit)
- Runs tests with Jest/Vitest/Mocha
- Detects frameworks automatically (React, Vue, Angular, Next.js, Node.js, React Native)
- Returns structured issues with locations and suggestions

**Used By**: `js-expert`, code-reviewer, frontend-developer

**Example Invocation**:
```
[invoke js-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "language": "typescript"
}
```

---

#### `swift-validator`
**Path**: `~/.claude/skills/swift-validator.md`

**Purpose**: Validate Swift code for correctness, style, and build integrity

**Validation Types**: compile, lint, format, build, deps, test, all

**What It Does**:
- Compiles Swift code using `swiftc` or Xcode
- Runs SwiftLint to detect style violations and best practices
- Checks formatting with SwiftFormat
- Builds Xcode projects/workspaces with xcodebuild
- Validates Swift Package Manager dependencies
- Runs XCTest suites and reports coverage
- Detects project type automatically (SPM, Xcode project, workspace)

**Used By**: `swift-expert`, code-reviewer, ios-developer

**Example Invocation**:
```
[invoke swift-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "scheme": "MyApp"
}
```

---

#### `cpp-validator`
**Path**: `~/.claude/skills/cpp-validator.md`

**Purpose**: Validate C++ code for correctness, style, and build integrity

**Validation Types**: compile, lint, format, static, build, test, all

**What It Does**:
- Compiles C++ code using g++ or clang++
- Runs clang-tidy for modernization and best practices
- Checks formatting with clang-format
- Performs static analysis with cppcheck
- Builds CMake projects
- Runs unit tests (doctest, Google Test, Catch2)
- Supports C++11 through C++23 standards

**Used By**: `cpp-expert`, code-reviewer, systems-developer

**Example Invocation**:
```
[invoke cpp-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "standard": "c++17"
}
```

---

#### `docker-executor`
**Path**: `~/.claude/skills/docker-executor.md`

**Purpose**: Execute Docker and container operations with structured output

**Supported Commands**: build, run, ps, logs, exec, stop, start, restart, rm, images, network, volume, compose

**What It Does**:
- Executes Docker commands and returns structured results
- Manages container lifecycle (create, start, stop, remove)
- Builds images and manages registries
- Handles Docker Compose operations
- Manages networks and volumes
- Includes safety checks for destructive operations
- Parses output into structured metadata

**Used By**: `container-expert`, devops-engineer, infrastructure-developer

**Example Invocation**:
```
[invoke docker-executor]
input: {
  "action": "docker",
  "command": "build",
  "args": {
    "dockerfile": "Dockerfile",
    "tag": "myapp:latest"
  }
}
```

---

#### `android-validator`
**Path**: `~/.claude/skills/android-validator.md`

**Purpose**: Validate Android applications for correctness, style, and build integrity

**Validation Types**: compile, lint, format, build, test, ndk, all

**What It Does**:
- Compiles Kotlin/Java code (kotlinc, javac)
- Runs Android Lint for Android-specific issues
- Checks formatting with ktlint
- Builds with Gradle (assembleDebug/assembleRelease)
- Runs unit tests (JUnit) and instrumentation tests
- Validates NDK/JNI native code (optional)
- Detects project type and module structure automatically

**Used By**: `android-expert`, code-reviewer, mobile-developer

**Example Invocation**:
```
[invoke android-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "module": "app"
}
```

---

#### `dotnet-validator`
**Path**: `~/.claude/skills/dotnet-validator.md`

**Purpose**: Validate .NET applications and libraries for correctness, style, and build integrity

**Validation Types**: compile, format, analyze, build, test, restore, all

**What It Does**:
- Compiles C#/F# code (Roslyn compiler)
- Checks formatting with dotnet format
- Runs Roslyn analyzers and code analysis
- Builds with dotnet build or msbuild
- Runs unit tests (xUnit, NUnit, MSTest)
- Validates NuGet package dependencies
- Supports .NET 6+, .NET Framework, .NET Standard

**Used By**: `dotnet-expert`, code-reviewer, dotnet-developer

**Example Invocation**:
```
[invoke dotnet-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "configuration": "Debug"
}
```

---

#### `dart-validator`
**Path**: `~/.claude/skills/dart-validator.md`

**Purpose**: Validate Flutter and Dart projects for correctness, style, and build integrity

**Validation Types**: analyze, format, build, test, pub, ffi, all

**What It Does**:
- Runs dart analyze for static analysis
- Checks formatting with dart format
- Builds Flutter apps for target platforms (iOS, Android, web, desktop)
- Runs unit, widget, and integration tests
- Validates pub package dependencies
- Checks FFI native bindings (optional)
- Detects Flutter apps vs pure Dart packages

**Used By**: `flutter-dart-expert`, code-reviewer, mobile-developer

**Example Invocation**:
```
[invoke dart-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "platform": "android"
}
```

---

#### `cmake-executor`
**Path**: `~/.claude/skills/cmake-executor.md`

**Purpose**: Execute CMake build system operations with structured output

**Supported Commands**: configure, build, test, install, clean, reconfigure, list-targets

**What It Does**:
- Configures projects with generators and options
- Builds targets with parallel execution
- Runs CTest test suites
- Installs artifacts to prefix
- Lists available targets
- Returns structured results with exit codes, output, metadata

**Used By**: `cmake-expert`, cpp-expert, build-engineer

**Example Invocation**:
```
[invoke cmake-executor]
input: {
  "action": "cmake",
  "command": "configure",
  "args": {
    "sourceDir": ".",
    "buildDir": "build",
    "generator": "Ninja"
  }
}
```

---

#### `make-executor`
**Path**: `~/.claude/skills/make-executor.md`

**Purpose**: Execute GNU Make build operations with structured output

**Supported Commands**: build, clean, install, test, check, all, distclean, custom

**What It Does**:
- Builds targets with parallel execution
- Cleans build artifacts
- Installs to prefix
- Runs tests
- Executes custom targets
- Returns structured results with exit codes, output, metadata

**Used By**: `make-expert`, build-engineer

**Example Invocation**:
```
[invoke make-executor]
input: {
  "action": "make",
  "command": "build",
  "args": {
    "target": "all",
    "parallel": 8
  }
}
```

---

#### `doxygen-validator`
**Path**: `~/.claude/skills/doxygen-validator.md`

**Purpose**: Validate Doxygen documentation comments in source code

**Supported Languages**: C++, C, Java, Python, other Doxygen-supported languages

**What It Does**:
- Validates cross-references and link generation (@ref, @see, \link)
- Checks tag usage (@param, @return, @throws, @brief, @details)
- Validates comment formatting and structure
- Identifies missing documentation and quality issues
- Returns structured issues by severity with suggestions
- Does NOT generate HTML/PDF documentation or modify source

**Used By**: `doxygen-expert`, tech-writer, documentation-reviewer

**Example Invocation**:
```
[invoke doxygen-validator]
input: {
  "action": "doxygen",
  "command": "validate",
  "args": {
    "path": "src/api.h",
    "checks": "all",
    "language": "cpp"
  }
}
```

---

#### `markdown-validator`
**Path**: `~/.claude/skills/markdown-validator.md`

**Purpose**: Validate Markdown documentation files for correctness and style

**Supported Flavors**: CommonMark, GitHub Flavored Markdown (GFM), Kramdown, Pandoc

**What It Does**:
- Checks Markdown syntax errors
- Validates style consistency (headings, lists, emphasis)
- Verifies internal and external links
- Checks code block formatting and tables
- Ensures accessibility (alt text, heading hierarchy)
- Returns structured issues by severity with fixable flag
- Does NOT convert or render Markdown

**Used By**: `tech-writer`, documentation-reviewer, markdown-expert

**Example Invocation**:
```
[invoke markdown-validator]
input: {
  "action": "markdown",
  "command": "validate",
  "args": {
    "path": "docs/",
    "checks": "all",
    "flavor": "gfm"
  }
}
```

---

#### `awk-executor`
**Path**: `~/.claude/skills/awk-executor.md`

**Purpose**: Execute AWK scripts and one-liners for data processing tasks

**Supported Modes**: one-liner, script, file, pipeline

**What It Does**:
- Executes AWK programs for pattern matching and text extraction
- Supports both macOS BSD awk and GNU awk (gawk)
- Handles field/record processing with custom separators
- Processes log files, CSV, TSV, and structured text data
- Supports preprocessing (grep, sort) and postprocessing pipelines
- Returns structured results with exit codes, output, metadata
- Auto-detects appropriate AWK variant based on script features

**Used By**: `awk-expert`, data-processor, log-analyzer

**Example Invocation**:
```
[invoke awk-executor]
input: {
  "action": "execute",
  "mode": "one-liner",
  "script": "{ count[$3]++ } END { for (k in count) print k, count[k] }",
  "inputFiles": ["server.log"],
  "options": {
    "fieldSeparator": " ",
    "postProcess": "sort -k2 -nr"
  }
}
```

---

#### `network-diagnostics`
**Path**: `~/.claude/skills/network-diagnostics.md`

**Purpose**: Execute network diagnostic commands for connectivity troubleshooting and analysis

**Supported Commands**: ping, traceroute, mtr, netstat, ss, tcpdump, dig, nslookup, ifconfig, ip, arp, route, nc

**What It Does**:
- Executes network diagnostic commands (ping, traceroute, netstat, tcpdump, etc.)
- Tests connectivity and measures latency
- Displays network configuration and interface status
- Monitors connections and bandwidth usage
- Performs DNS lookups and packet capture
- Returns structured results with exit codes, output, parsed metadata
- Handles platform differences (macOS, Linux, Windows)

**Used By**: `network-expert`, infrastructure-developer, devops-engineer

**Example Invocation**:
```
[invoke network-diagnostics]
input: {
  "action": "diagnose",
  "command": "ping",
  "args": {
    "host": "8.8.8.8",
    "count": 5,
    "timeout": 10
  }
}
```

---

#### `ml-executor`
**Path**: `~/.claude/skills/ml-executor.md`

**Purpose**: Execute machine learning operations for model training, evaluation, and inference

**Supported Frameworks**: TensorFlow/Keras, PyTorch, scikit-learn, XGBoost, LightGBM

**What It Does**:
- Trains ML models with specified configurations
- Evaluates models on test/validation data and computes metrics
- Runs inference/predictions on new data
- Performs data preprocessing and augmentation
- Executes hyperparameter tuning (grid search, random search, Bayesian optimization)
- Manages models (save, load, convert formats)
- Returns structured results with metrics, predictions, training logs, artifacts
- Supports GPU acceleration with auto-detection

**Used By**: `ml-expert`, data-scientist, ml-engineer

**Example Invocation**:
```
[invoke ml-executor]
input: {
  "action": "train",
  "framework": "pytorch",
  "config": {
    "modelScript": "train_model.py",
    "dataPath": "data/train/",
    "epochs": 50,
    "batchSize": 32,
    "learningRate": 0.001,
    "validationSplit": 0.2
  },
  "outputDir": "models/run1",
  "gpuEnabled": true
}
```

---

#### `http-client`
**Path**: `~/.claude/skills/http-client.md`

**Purpose**: Execute HTTP requests for REST API testing and integration

**Supported Methods**: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS

**What It Does**:
- Executes HTTP requests with various methods and payloads
- Handles authentication (Bearer, Basic, API key, OAuth1/2, Digest, custom)
- Supports multiple content types (JSON, XML, form data, multipart, binary)
- Manages headers, query parameters, and request/response bodies
- Implements retry logic with exponential backoff
- Handles file uploads and downloads
- Returns structured results with status codes, headers, body, timing metadata
- Validates SSL certificates and reports TLS version

**Used By**: `rest-expert`, api-developer, integration-engineer

**Example Invocation**:
```
[invoke http-client]
input: {
  "action": "request",
  "method": "POST",
  "url": "https://api.example.com/v1/users",
  "auth": {
    "type": "bearer",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  },
  "body": {
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

---

#### `diagram-generator`
**Path**: `~/.claude/skills/diagram-generator.md`

**Purpose**: Generate, validate, and render diagrams using diagram-as-code tools

**Supported Tools**: Mermaid, PlantUML, GraphViz (DOT), D2

**What It Does**:
- Generates diagram syntax for flowcharts, sequence diagrams, class diagrams, ER diagrams, etc.
- Validates diagram syntax for correctness
- Renders diagrams to output formats (SVG, PNG, PDF)
- Supports multiple themes and styling options
- Batch processes multiple diagrams
- Returns structured results with validation status, rendered artifacts, metadata
- Handles Mermaid (12+ diagram types), PlantUML (8+ diagram types), GraphViz, D2

**Used By**: `uml-expert`, architecture-designer, documentation-generator

**Example Invocation**:
```
[invoke diagram-generator]
input: {
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "flowchart",
  "syntax": "graph TD\\n  A[Start] --> B{Decision}\\n  B -->|Yes| C[Process]\\n  B -->|No| D[End]",
  "outputFormat": "svg",
  "outputPath": "diagrams/flow.svg"
}
```

---

#### `embedded-toolchain`
**Path**: `~/.claude/skills/embedded-toolchain.md`

**Purpose**: Execute embedded systems development operations for microcontrollers and SBCs

**Supported Platforms**: Arduino, ESP32/ESP8266, STM32, nRF52, Raspberry Pi Pico, AVR, RISC-V

**What It Does**:
- Compiles firmware for embedded platforms (Arduino CLI, ESP-IDF, ARM GCC, PlatformIO)
- Flashes firmware to devices (avrdude, esptool, OpenOCD, J-Link)
- Monitors serial communication (read/write serial ports)
- Starts debugging sessions (GDB, OpenOCD)
- Lists and detects connected devices
- Manages filesystem uploads (SPIFFS, LittleFS)
- Returns structured results with build output, flash status, serial data, memory usage

**Used By**: `embedded-expert`, iot-developer, firmware-engineer

**Example Invocation**:
```
[invoke embedded-toolchain]
input: {
  "action": "compile",
  "platform": "esp32",
  "toolchain": "esp-idf",
  "projectPath": "my-project/",
  "board": "esp32dev",
  "config": {
    "optimization": "O2"
  }
}
```

---

## Future Skills Candidates

_No agents awaiting conversion at this time._

---

## Skill Development Guidelines

### Structure

Each skill is a markdown file with:

1. **Header**: Name and one-line description
2. **Capability**: What the skill does
3. **Supported Options**: Frameworks, languages, tools it handles
4. **Usage Protocol**: How agents invoke it
5. **Input/Output Contract**: Clear data format
6. **Constraints**: What it explicitly does NOT do
7. **Error Handling**: How it reports failures

### Design Principles

**Skills are tools, not agents:**
- No autonomous reasoning
- No decision-making
- No modification of behavior based on context

**Skills are focused:**
- One primary responsibility
- Clear input/output contract
- Reusable across multiple agents

**Skills are transparent:**
- Return raw results (no interpretation)
- No filtering or summarization
- Complete error messages included

### Example Usage in Agents

```yaml
---
name: my-agent
skills:
  - test-runner
  - code-browser
---

When the agent needs tests:
[invoke test-runner skill]

When the agent needs to search code:
[invoke code-browser skill]
```

---

## Version

Created: 2025-12-13
Last Updated: 2025-12-14 (added awk-executor, network-diagnostics, ml-executor, http-client, diagram-generator, embedded-toolchain)
