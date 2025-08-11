# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a comprehensive personal development workspace where the entire home directory (`/Users/phatblat`) is managed as a Git repository. The workspace focuses on multi-platform SDK development, particularly for Ditto (real-time synchronization platform), and covers extensive mobile/cross-platform development.

### Key Directories

- `dev/` - Main development workspace organized by technology/platform
- `dev/ditto/` - Ditto ecosystem projects (Rust core, multi-platform SDKs)
- `dev/swift/` - Swift projects, Apple platform development
- `dev/kotlin/`, `dev/kmp/` - Kotlin and Kotlin Multiplatform projects
- `dev/android/` - Android-specific projects including automotive (AAOS)
- `dev/rust/` - Rust projects and learning experiments
- `bin/` - Custom scripts and utilities
- `.config/` - Modern configuration files (Fish shell, mise, etc.)

## Shell Environment

**Primary Shell**: Fish Shell with extensive customization
- Configuration: `~/.config/fish/config.fish`
- Variables: `~/.config/fish/variables.fish`
- 700+ custom functions in `~/.config/fish/functions/`
- Modern CLI tools: starship (prompt), zoxide (cd), fzf (fuzzy finder)

**Tool Management**: mise (modern replacement for asdf)
- Global config: `~/.config/mise/config.toml`
- Project-specific: `mise.toml` files in project directories
- Manages: Node.js, Python, Ruby, Java, Terraform, .NET, etc.

## Common Development Commands

### Package Management
```fish
# Update all packages via custom Fish function
🍺_brew  # Updates Homebrew packages
🐠_omf   # Updates Oh My Fish packages
mise upgrade  # Updates mise-managed tools
```

### Build Systems
Most projects use one of:
- `justfile` - Modern task runner (preferred for new projects)
- `Makefile` - Traditional make (used in complex multi-platform builds)
- `build.gradle.kts` - Kotlin-based Gradle builds

```bash
# For justfile-based projects
just          # List available tasks
just build    # Build project
just test     # Run tests
just lint     # Run linters

# For Makefile-based projects
make          # Default target
make build    # Build project
make test     # Run tests
make clean    # Clean build artifacts

# For Gradle-based projects (Kotlin/Java)
./gradlew build   # Build project
./gradlew test    # Run tests
./gradlew clean   # Clean build artifacts
```

### Development Workflow
```fish
# Environment setup for new projects
mise install  # Install project tools
direnv allow  # Load project environment variables (if .envrc exists)

# Common development tasks
mise exec -- <command>  # Run command with project tools
```

### Testing Commands
```bash
# Rust projects
cargo test                    # Run all tests
cargo test --workspace       # Test entire workspace
cargo test -- --nocapture    # Show println! output

# Swift projects
swift test                   # Run all tests
swift test --parallel       # Run tests in parallel

# Kotlin/Gradle projects
./gradlew test              # Run unit tests
./gradlew connectedTest     # Run instrumented tests (Android)
./gradlew check             # Run all verification tasks

# Ditto specific
make test                   # Run core tests
make test-android          # Run Android SDK tests
make test-ios              # Run iOS SDK tests
```

### Linting and Formatting
```bash
# Rust
cargo fmt                   # Format code
cargo fmt --check          # Check formatting without changes
cargo clippy               # Run linter
cargo clippy -- -D warnings # Treat warnings as errors

# Kotlin
./gradlew ktlintCheck      # Check code style
./gradlew ktlintFormat     # Auto-format code
./gradlew detekt           # Static code analysis

# Swift
swiftlint                  # Lint code (if installed)
swift-format               # Format code (if installed)
```

## Git Configuration

- GPG commit signing enabled by default
- Uses Kaleidoscope for diff/merge operations
- Delta pager for enhanced git output
- Comprehensive aliases in `.gitconfig`

**Key Git Aliases**:
- `git lg` - Pretty log with graph
- `git l` - Compact log format
- `git all` - All branches log

## Architecture Overview

### Ditto Ecosystem
The primary focus is on Ditto, a real-time synchronization platform:
- **Core**: Rust-based with WebAssembly support
- **SDKs**: iOS/macOS (Swift), Android (Kotlin), .NET, React Native, Flutter
- **Architecture**: FFI-based with Rust core and language-specific bindings
- **Build System**: Complex multi-platform builds with extensive cross-compilation

### Development Patterns
1. **Rust-centric approach**: Core functionality in Rust with FFI bindings
2. **Multi-platform targeting**: iOS, Android, macOS, Windows, Linux
3. **Modern tooling**: mise, justfile, Fish shell, modern CLI tools
4. **Infrastructure as Code**: Ansible, Terraform, comprehensive automation

### Cross-Platform Development
- **Mobile-first**: Strong focus on iOS and Android
- **Cross-compilation**: Extensive support for multiple target platforms
- **Tool version management**: Consistent environments via mise
- **Build automation**: Sophisticated CI/CD pipelines

## Project-Specific Notes

### Ditto Projects (`dev/ditto/`)
- Main project: `dev/ditto/ditto/` (Rust core)
- Use `make` for builds (complex multi-platform Makefile)
- Extensive cross-compilation support
- CI/CD via Buildkite with custom infrastructure

**Common Ditto Commands**:
```bash
make                    # Build default targets
make test              # Run all tests
make test-rust         # Run Rust tests only
make build-android     # Build Android SDK
make build-ios         # Build iOS SDK
make clean             # Clean all build artifacts
```

### KMP Projects (`dev/kmp/`)
- Kotlin Multiplatform Mobile projects
- Gradle-based builds (`build.gradle.kts`)
- Focus on Rust integration with KMP
- Use `mise` for tool management

**Common KMP Commands**:
```bash
./gradlew build                    # Build all targets
./gradlew :shared:test            # Test shared module
./gradlew :androidApp:assembleDebug # Build Android app
./gradlew :shared:iosSimulatorArm64Test # Test iOS
```

### Swift Projects (`dev/swift/`)
- Swift Package Manager projects
- Use `swift build`, `swift test`
- Some use Xcode projects (.xcodeproj)
- Apple platform development focus

## Development Environment

### Required Tools
Essential tools managed via mise and Homebrew:
- Fish shell with custom functions
- mise (tool version management)
- just (task runner)
- Starship (prompt)
- Git with GPG signing
- Platform-specific SDKs (Android, iOS, etc.)

### Fish Shell Functions
The workspace includes 700+ custom Fish functions providing shortcuts for:
- Package management across all tools
- Development workflows
- File operations
- System administration
- Cross-platform compatibility

### IDE/Editor Support
- Multiple editors supported: Vim, VS Code, Cursor
- EditorConfig for consistent formatting
- Git hooks for quality control
- Comprehensive linting/formatting tools

## Notes for Development

### Working with Fish Shell
- Functions are auto-loaded from `~/.config/fish/functions/`
- Use `funced <function-name>` to edit functions
- Use `funcsave <function-name>` to save functions
- Most development tasks have dedicated functions

### Cross-Platform Considerations
- Projects often target multiple platforms simultaneously
- Use mise for consistent tool versions across platforms
- Be aware of platform-specific paths and configurations
- Many projects have platform detection logic

### Build System Preferences
- New projects prefer `justfile` over `Makefile`
- Gradle used for Java/Kotlin projects
- Rust projects use Cargo
- Complex multi-platform builds still use Make

This workspace represents a sophisticated, enterprise-level development environment focused on real-time synchronization technology with emphasis on multi-platform SDK development and modern developer experience.

## Troubleshooting

### Common Build Issues

**Rust/Cargo Issues**:
```bash
# Clear cargo cache if builds fail
cargo clean
rm -rf ~/.cargo/registry/cache

# Update dependencies
cargo update

# Check for outdated dependencies
cargo outdated
```

**Android Build Issues**:
```bash
# Clean Android build cache
./gradlew clean
./gradlew --stop  # Stop Gradle daemon
rm -rf ~/.gradle/caches

# Ensure Android SDK is properly set
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

**iOS/macOS Build Issues**:
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset Swift Package Manager cache
swift package reset

# Update CocoaPods (if used)
pod repo update
pod install
```

### Environment Setup Issues

**mise Tool Version Conflicts**:
```bash
# Reset mise plugins
mise plugins update

# Reinstall specific tool
mise uninstall <tool>@<version>
mise install <tool>@<version>

# Check which tools are installed
mise list
```

**Fish Shell Issues**:
```fish
# Reload configuration
source ~/.config/fish/config.fish

# Debug function loading
functions -v <function-name>

# Clear Fish command history if corrupted
rm ~/.local/share/fish/fish_history
```

## Quick Start Guides

### Starting a New Rust Project
```bash
cd dev/rust
cargo new my-project
cd my-project
echo "rust = \"stable\"" > mise.toml
mise install
just init  # If using justfile
```

### Starting a New KMP Project
```bash
cd dev/kmp
# Use Android Studio's KMP wizard or:
git clone https://github.com/Kotlin/kmm-basic-sample.git my-project
cd my-project
mise install
./gradlew build
```

### Starting a New Swift Package
```bash
cd dev/swift
mkdir my-package && cd my-package
swift package init --type library
# or --type executable for CLI tools
swift build
swift test
```

## CI/CD Integration

### Running CI Checks Locally

**For Buildkite Projects**:
```bash
# Install buildkite CLI
brew install buildkite/buildkite/bk

# Run pipeline locally (requires Docker)
bk local run

# Validate pipeline without running
bk pipeline validate
```

**Pre-push Checks**:
```bash
# Run these before pushing to avoid CI failures
just lint      # If justfile exists
just test
cargo fmt --check  # For Rust projects
./gradlew check    # For Gradle projects
```

## Additional Resources

- **Ditto Documentation**: Internal docs in `dev/ditto/docs/`
- **Fish Shell Docs**: https://fishshell.com/docs/current/
- **mise Documentation**: https://mise.jdx.dev/
- **Just Documentation**: https://just.systems/

## Nushell Migration Note

This workspace is currently experimenting with Nushell as a potential replacement for Fish shell. The `nushell` branch contains experimental configurations. Fish shell remains the primary shell for now.