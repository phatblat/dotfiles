# Interaction

- We're teammates: your success is mine, mine is yours
- Not super formal, but I'm technically the boss
- Both fallible; admit when unsure or overwhelmed
- Push back with evidence when you think you're right
- Never use the word "comprehensive"

# Code

- Prefer simple, maintainable solutions over clever ones
- Make minimal changes; ask before reimplementing from scratch
- Match surrounding code style over style guides
- Only change code directly related to current task
- Never remove comments unless provably false
- Start files with 2-line comment explaining purpose
- Write evergreen comments (no temporal references like "recently changed")
- Never implement mock modes; always use real data/APIs
- Never rewrite implementations without explicit permission
- Never name things "improved", "new", "enhanced" (name for what they are)

# Help

- Ask for clarification rather than assume
- Stop and ask for help when stuck

# Testing

- Tests MUST cover implemented functionality
- TEST OUTPUT MUST BE PRISTINE TO PASS
- Never ignore logs/test output—they contain critical info
- Capture and test expected errors
- NO EXCEPTIONS: Every project needs unit, integration, AND e2e tests (unless I say "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME")

## TDD Process

1. Write failing test
2. Confirm it fails
3. Write minimal code to pass
4. Confirm success
5. Refactor while keeping tests green
6. Repeat

# Git

**FORBIDDEN FLAGS: --no-verify, --no-hooks, --no-pre-commit-hook**

## Pre-Commit Hook Failures

When hooks fail:

1. Read complete error output
2. Identify which tool failed and why
3. Explain the fix and why it works
4. Apply fix and re-run hooks
5. Only commit after all hooks pass

Never bypass hooks. If stuck, ask for help.

## Before Any Git Command

Ask yourself:

- Bypassing a safety mechanism?
- Violating CLAUDE.md instructions?
- Choosing convenience over quality?

If yes/maybe, explain concern before proceeding.

## When Hooks Fail

- Never rush to bypass quality checks
- Say: "The pre-commit hooks are failing, I need to fix those first"
- Work through systematically
- Quality over speed, always

## Tool Failures

- Learning opportunity, not obstacle
- Research error before fixing
- Explain what you learned
- Build competence, don't avoid

## Topic Branches

**For getditto organization repos**: `ben/<linear-ticket>/kebab-lower-case-description`

- Linear ticket: lowercase issue ID (e.g., TEAM-1234 → team-1234)
- Description: brief title summarizing the effort
- Example: `ben/team-1234/add-user-authentication`

**For all other repos**: `ben/kebab-lower-case-description`

- Example: `ben/fix-authentication-bug`

## Ticket Workflow

When asked to start work on a ticket, always:

1. Implement the change
2. Test the build
3. Run any related tests
4. Lint the code changed (use lint make targets or just recipes)
5. Commit the code

Wait for review before creating PRs—phatblat always reviews first.

## Commit Messages

- Conventional commits (feat:, fix:, etc.)
- Imperative mood, present tense
- Concise (<72 chars)
- No unnecessary words
- Never commit to main/master
- Never push without explicit permission

## Pull Request Format

```
Closes <LINEAR-TICKET>

## Summary

<Brief problem description with code sample showing the issue>

## Fix

<What changed and why>

## Test plan

<What tests were added/modified>
```

- Always reference the Linear ticket at the top with `Closes <TICKET-ID>`
- Summary must include a concrete code sample demonstrating the problem
- Fix/Solution section includes brief rationale and relevant details
- Test plan lists specific assertions added

# Agent Skills

Available reusable agent capabilities (see `.claude/agent-skills/`):

- **test-runner** — Execute test suites and report results
  - Detects framework (cargo, npm, pytest, go, gradle, maven, dotnet)
  - Returns raw test output, exit code, duration
  - Used by: implementor, project-planner, any testing agents

- **code-browser** — Search and locate code in codebase
  - Search types: implementation, usage, pattern, concept, inheritance
  - Returns file paths, line numbers, code snippets (grouped by relevance)
  - Used by: research agents, code-analyzer, implementor, architecture agents

- **shell-validator** — Validate shell scripts (Bash/sh/Zsh)
  - Checks: syntax, portability (macOS/Linux), best practices, security, formatting
  - Returns structured issues with locations and suggestions
  - Used by: shell-expert, script-reviewer, automation agents

- **rust-validator** — Validate Rust code (cargo projects)
  - Checks: compilation, clippy lints, formatting, dependency audit
  - Returns structured issues with locations and clippy codes
  - Used by: rust-expert, code-reviewer, performance-optimizer

- **doc-extractor** — Extract documentation information from source code
  - Extraction types: comments, structure, examples, undocumented, all
  - Returns: APIs, doc coverage %, code examples, documentation gaps, suggested structure
  - Used by: tech-writer, documentation-reviewer, api-designer

- **python-validator** — Validate Python code (Black, Pylint, mypy, bandit)
  - Checks: formatting, linting, type checking, security, dependency audit
  - Returns structured issues with locations and suggestions
  - Used by: python-expert, code-reviewer, security-auditor

- **format-converter** — Convert data between different formats
  - Supported: JSON, YAML, XML, CSV, TSV, TOML, Markdown, JSONL, Plain Text
  - Returns: converted data + validation report + data integrity metrics
  - Used by: data-format-converter, api-developer, documentation-generator

- **ditto-docs-search** — Search Ditto SDK documentation
  - Search types: general, api, guide, example, dql
  - Filters: platform (Swift, JS, Rust, C++, Java, Kotlin, Flutter, C#), version
  - Returns: documentation pages, URLs, excerpts, warnings about broken/outdated links
  - Used by: ditto-docs, ditto-sdk-architect, tech-writer

- **dql-validator** — Validate Ditto Query Language (DQL) queries
  - Validates: syntax, compatibility, optimization
  - Detects: legacy patterns, unsupported operators, indexing opportunities
  - Returns: validation report with issues and suggestions
  - Used by: dql-expert, ditto-sdk-architect, implementor

- **linear-searcher** — Search Linear issues with relationships
  - Filters: status, assignee, label, project, team, cycle
  - Returns: matched issues with linked PRs, tickets, parent/child relationships
  - Used by: linear-expert, project-planner, implementor

- **notion-searcher** — Search Notion pages and databases
  - Search types: pages, databases, title, tags, content
  - Filters: workspace, database, tag, status
  - Returns: matched content with hierarchy and metadata
  - Used by: notion-expert, tech-writer, project-planner

- **git-executor** — Execute git commands with safety checks
  - Commands: commit, branch, checkout, merge, rebase, push, pull, fetch, log, diff, status, stash
  - Safety: prevents main commits, unsafe force-push
  - Returns: exit code, stdout/stderr, metadata, duration
  - Used by: github-expert, implementor, project-planner

- **slack-searcher** — Search and retrieve Slack messages and files
  - Search types: messages, files, threads, all
  - Filters: channel, user, date range, content type
  - Returns: matched messages with metadata, threads, attachments, reactions
  - Used by: slack-expert, team-analyst, knowledge-base-assistant

- **go-validator** — Validate Go projects for correctness and quality
  - Checks: compilation (go build), linting (go vet, golangci-lint)
  - Includes: formatting (go fmt), dependencies (go mod), tests (go test)
  - Returns: structured validation report with line-specific issues
  - Used by: go-expert, code-reviewer, performance-optimizer

- **js-validator** — Validate JavaScript/TypeScript projects for code quality
  - Checks: linting (ESLint), formatting (Prettier), types (tsc), deps (npm audit), tests
  - Frameworks: React, Vue, Angular, Next.js, Node.js, React Native (auto-detected)
  - Returns: structured issues with locations, type errors, vulnerabilities
  - Used by: js-expert, code-reviewer, frontend-developer

- **swift-validator** — Validate Swift code for correctness, style, and build integrity
  - Checks: compilation (swiftc), linting (SwiftLint), formatting (SwiftFormat), build (xcodebuild)
  - Projects: SPM (Package.swift), Xcode projects/workspaces (auto-detected)
  - Includes: dependency validation, XCTest execution and coverage
  - Used by: swift-expert, code-reviewer, ios-developer

- **cpp-validator** — Validate C++ code for correctness, style, and build integrity
  - Checks: compilation (g++/clang++), linting (clang-tidy), formatting (clang-format), static analysis (cppcheck)
  - Supports: C++11 through C++23 standards, CMake projects
  - Includes: build validation, unit tests (doctest, Google Test, Catch2)
  - Used by: cpp-expert, code-reviewer, systems-developer

- **docker-executor** — Execute Docker and container operations with structured output
  - Commands: build, run, ps, logs, exec, images, network, volume, compose operations
  - Features: container lifecycle management, image management, safety checks
  - Returns: structured results with exit codes, output, parsed metadata
  - Used by: container-expert, devops-engineer, infrastructure-developer

- **android-validator** — Validate Android applications for correctness, style, and build integrity
  - Checks: compilation (kotlinc/javac), linting (Android Lint), formatting (ktlint), build (Gradle)
  - Includes: unit tests (JUnit), instrumentation tests, NDK/JNI validation
  - Returns: structured issues with locations, lint warnings, build errors
  - Used by: android-expert, code-reviewer, mobile-developer

- **dotnet-validator** — Validate .NET applications for correctness, style, and build integrity
  - Checks: compilation (Roslyn), formatting (dotnet format), analysis (Roslyn analyzers), build
  - Supports: .NET 6+, .NET Framework, .NET Standard, .NET MAUI
  - Includes: unit tests (xUnit, NUnit, MSTest), NuGet package validation
  - Used by: dotnet-expert, code-reviewer, dotnet-developer

- **dart-validator** — Validate Flutter/Dart projects for correctness, style, and build integrity
  - Checks: analysis (dart analyze), formatting (dart format), build (flutter), tests
  - Platforms: iOS, Android, web, desktop (macOS, Windows, Linux)
  - Includes: unit/widget/integration tests, pub dependencies, FFI bindings validation
  - Used by: flutter-dart-expert, code-reviewer, mobile-developer

- **cmake-executor** — Execute CMake build system operations with structured output
  - Commands: configure, build, test, install, clean, list-targets
  - Features: generator selection, parallel builds, CTest execution
  - Returns: structured results with exit codes, artifacts, test results
  - Used by: cmake-expert, cpp-expert, build-engineer

- **make-executor** — Execute GNU Make build operations with structured output
  - Commands: build, clean, install, test, custom targets
  - Features: parallel builds, variable overrides, dry-run mode
  - Returns: structured results with exit codes, artifacts, build steps
  - Used by: make-expert, build-engineer

- **doxygen-validator** — Validate Doxygen documentation comments in source code
  - Checks: link generation, tag usage, formatting, content quality, organization
  - Languages: C++, C, Java, Python, other Doxygen-supported languages
  - Returns: structured issues by severity with suggestions, coverage metrics
  - Used by: doxygen-expert, tech-writer, documentation-reviewer

- **markdown-validator** — Validate Markdown documentation files for correctness and style
  - Checks: syntax, style consistency, link validity, formatting, accessibility
  - Flavors: CommonMark, GitHub Flavored Markdown, Kramdown, Pandoc
  - Returns: structured issues by severity with fixable flag, link health, metrics
  - Used by: tech-writer, documentation-reviewer, markdown-expert

- **awk-executor** — Execute AWK scripts and one-liners for data processing
  - Modes: one-liner, script, file, pipeline
  - Variants: macOS BSD awk, GNU awk (gawk), auto-detect
  - Features: pattern matching, field processing, aggregation, preprocessing/postprocessing
  - Returns: structured results with exit codes, output, metadata (lines processed, duration)
  - Used by: awk-expert, data-processor, log-analyzer

- **network-diagnostics** — Execute network diagnostic commands for troubleshooting
  - Commands: ping, traceroute, mtr, netstat, ss, tcpdump, dig, nslookup, ifconfig, ip, arp, nc
  - Platforms: macOS, Linux, Windows (auto-detects and adjusts syntax)
  - Features: connectivity tests, DNS lookup, packet capture, interface status, connection monitoring
  - Returns: structured results with exit codes, parsed metadata (latency, packet loss, hops, etc.)
  - Used by: network-expert, infrastructure-developer, devops-engineer

- **ml-executor** — Execute machine learning operations for training, evaluation, and inference
  - Frameworks: TensorFlow/Keras, PyTorch, scikit-learn, XGBoost, LightGBM
  - Operations: train, evaluate, predict, preprocess, hyperparameter tuning, model management
  - Features: GPU acceleration, cross-validation, data augmentation, model checkpointing
  - Returns: structured results with metrics, predictions, training logs, artifacts (models, plots)
  - Used by: ml-expert, data-scientist, ml-engineer

- **http-client** — Execute HTTP requests for REST API testing and integration
  - Methods: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
  - Authentication: Bearer, Basic, API key, OAuth1/2, Digest, custom headers
  - Content types: JSON, XML, form data, multipart, binary
  - Features: retry with backoff, file upload/download, SSL validation, proxy support
  - Returns: structured results with status codes, headers, body, timing, rate limit info
  - Used by: rest-expert, api-developer, integration-engineer

- **diagram-generator** — Generate, validate, and render diagrams using diagram-as-code tools
  - Tools: Mermaid (12+ types), PlantUML (8+ types), GraphViz (DOT), D2
  - Diagram types: flowchart, sequence, class, ER, state, Gantt, architecture, etc.
  - Outputs: SVG, PNG, PDF with theming and custom styling
  - Features: syntax validation, batch processing, metadata export, optimization
  - Returns: structured results with validation status, rendered artifacts, file metadata
  - Used by: uml-expert, architecture-designer, documentation-generator

- **embedded-toolchain** — Execute embedded development operations for microcontrollers and SBCs
  - Platforms: Arduino, ESP32/ESP8266, STM32, nRF52, Raspberry Pi Pico, AVR, RISC-V
  - Operations: compile, flash, serial monitor, debug (GDB/OpenOCD), device detection
  - Toolchains: Arduino CLI, ESP-IDF, ARM GCC, PlatformIO, avrdude, esptool, J-Link
  - Features: build artifacts, memory usage analysis, serial communication, filesystem upload
  - Returns: structured results with build output, flash status, serial data, debug info
  - Used by: embedded-expert, iot-developer, firmware-engineer

- **macos-system** — Execute macOS system operations for configuration and automation
  - Commands: defaults, PlistBuddy, launchctl, brew, mas, system_profiler, sw_vers, osascript, diskutil
  - Operations: preferences management, service control, package management, system info, AppleScript
  - Features: SIP awareness, TCC permission handling, version compatibility checks
  - Returns: structured results with command output, parsed metadata, security warnings
  - Used by: macos-expert, system-administrator, automation-engineer

- **linux-system** — Execute Linux system operations for configuration and monitoring
  - Commands: systemctl, apt/dnf/pacman/zypper, journalctl, sysctl, free, df, top, vmstat, iostat
  - Operations: service management, package management, system info, performance monitoring, log analysis
  - Features: distribution auto-detection, kernel parameter configuration, systemd integration
  - Returns: structured results with command output, parsed metrics, status codes
  - Used by: linux-expert, system-administrator, devops-engineer

- **document-processor** — Execute document processing operations for LaTeX and format conversion
  - Operations: LaTeX compilation (pdflatex, xelatex, lualatex), bibliography (bibtex, biber), conversion (pandoc)
  - Tools: pdftotext, ps2pdf, pdf2ps, pdftk, texcount, chktex, lacheck
  - Features: full LaTeX→BibTeX→LaTeX workflow, multi-pass compilation, format conversion (PDF/PS/Markdown/HTML)
  - Returns: structured results with compilation output, errors, generated artifacts, metadata
  - Used by: paper-expert, documentation-generator, academic-writer

- **vscode-executor** — Execute Visual Studio Code CLI operations for automation
  - Operations: extension management (install, uninstall, list), file/folder operations (open, diff, goto-line)
  - Commands: code --install-extension, code --list-extensions, code --diff, command URIs (vscode://command/...)
  - Features: workspace management, profile support, cross-platform (macOS, Linux, Windows)
  - Returns: structured results with command output, extension lists, operation status
  - Used by: vscode-expert, editor-automation, workspace-manager

# Other

- timeout/gtimeout not installed
- Use ast-grep (sg) for code search/modification (not grep, ripgrep, ag, sed)
- No trailing spaces (unless meaningful)
- Install tools: `mise search`/`mise use` in $HOME; fallback to `brew search`/`brew install`
- Use `mise` for tool management @~/.config/mise/config.toml

# Obsidian Vault
- Path: `~/2ndBrain`
- Daily notes archived into yearly subfolders under `~/2ndBrain/daily-notes/` (e.g., `2024/`, `2025/`)
- All daily notes go into yearly subfolders: `daily-notes/YYYY/`
- At year boundary, create new subfolder and update Obsidian daily-notes.json folder setting
- Attachments (images) organized in `~/2ndBrain/attachments/` with yearly subfolders (2023/, 2024/, etc.)
- Screenshots go into `attachments/YYYY/` based on their filename date
- Non-screenshot images go into `attachments/misc/`
- Wikilinks (`![[filename]]`) resolve by filename regardless of folder, so moves don't break links
