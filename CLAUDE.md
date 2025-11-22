# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

Personal development workspace with home directory (`/Users/phatblat`) as Git repository.

### Key Directories

- `dev/` - Main development workspace
- `bin/` - Custom scripts and utilities
- `.config/` - Configuration files

## Shell Environment

**Primary Shell**: Fish Shell

- Config: `~/.config/fish/config.fish`
- Custom functions: `~/.config/fish/functions/`

**Secondary Shell**: Nushell (actively being configured)

- Config: `~/.config/nushell/`
- History: `Library/Application Support/nushell/history.txt` (gitignored)

**Tool Management**: mise

- Global: `~/.config/mise/config.toml`
- Project: `mise.toml` files
- Recent additions: claude-code-router, ast-grep, docker-cli, docker-compose, yq

## Development Standards

### Code Quality

- Prefer simple, maintainable solutions over clever ones
- Match existing code style within each file
- Make minimal changes to achieve desired outcomes
- Never use `--no-verify` when committing
- Ask for clarification rather than making assumptions

### Testing

- Practice TDD - write tests first
- All tests must pass before committing
- Test output must be pristine to pass

### Git Workflow

- GPG commit signing enabled
- Use descriptive commit messages using conventional commit style
- Create feature branches for new work
- Git rerere enabled for conflict resolution

## Communication

- Address me as "phatblat"
- We're colleagues working together
- Ask for help when needed
- Push back with evidence when you think you're right

## Editor Configuration

**Zed**: Primary editor

- Rust analyzer: Custom CARGO_TARGET_DIR with analyzerTargetDir enabled
- Tab size: 2 spaces
- Hard tabs disabled
- Private values redaction disabled

## Project-Specific Configuration

For detailed project instructions, check for CLAUDE.md files in project directories.
