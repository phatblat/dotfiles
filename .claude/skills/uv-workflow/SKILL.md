---
name: uv-workflow
description: |-
  Master uv package manager for Python: project setup, dependency management, virtual environments,
  lockfiles, CI/CD integration, Docker builds, and migration from pip/poetry.
  MUST BE USED when user mentions: "uv", "uv add", "uv run", "uv sync", "uv init", "uv lock",
  "uv venv", "uv pip", "pyproject.toml", "python project setup", "python dependencies",
  "virtual environment", "venv", "pip install", "poetry to uv", "migrate from pip",
  "lockfile python", "requirements.txt", "setup.py", "pip freeze", "uv tool",
  "install package", "add dependency", "python environment", "new python project",
  "package manager python", "create project", "uv export", "uv cache", "uv python".
  10-100x faster than pip. Covers init, add, sync, lock, run, Docker, CI/CD.
  NOT for npm/pnpm/yarn (JS toolchain), Rust cargo, or deployment (use deployment-assistant).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - mcp__context7__resolve-library-id
  - mcp__context7__get-library-docs
---

# UV Package Manager

Ultra-fast Python package installer and resolver written in Rust. 10-100x faster than pip.

## Quick Reference

```bash
# Project lifecycle
uv init my-project          # Create project
uv add requests pandas      # Add deps
uv add --dev pytest ruff    # Add dev deps
uv remove package           # Remove
uv sync                     # Install all from pyproject.toml
uv lock                     # Generate/update lockfile
uv run pytest               # Run in venv (no activation needed)

# Virtual environments
uv venv                     # Create .venv
uv venv --python 3.12       # With specific Python
uv python install 3.12      # Install Python version
uv python pin 3.12          # Pin for project

# pip-compatible
uv pip install -r requirements.txt
uv pip freeze > requirements.txt
```

## Project Setup Pattern

```bash
uv init my-project && cd my-project
uv python pin 3.12
uv add fastapi uvicorn pydantic
uv add --dev pytest ruff mypy black
mkdir -p src/my_project tests
uv run pytest
```

Creates: `pyproject.toml`, `.python-version`, `uv.lock`, `.venv/`

## pyproject.toml Standard

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "ruff>=0.1.0",
    "mypy>=1.5.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = []

[tool.uv.workspace]
members = ["packages/*"]  # For monorepos
```

## Lockfile Workflow

```bash
uv lock                     # Create/update uv.lock
uv sync --frozen            # Install exact versions (CI)
uv lock --upgrade           # Upgrade all
uv lock --upgrade-package requests  # Upgrade one
uv lock --check             # Verify lockfile is current
uv export --format requirements-txt > requirements.txt  # Export
```

**Rule**: Always commit `uv.lock` to version control.

## Docker Integration

```dockerfile
FROM python:3.12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-editable

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv .venv
COPY . .
ENV PATH="/app/.venv/bin:$PATH"
CMD ["python", "app.py"]
```

## CI/CD (GitHub Actions)

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v2
        with:
          enable-cache: true
      - run: uv python install 3.12
      - run: uv sync --all-extras --dev
      - run: uv run pytest
      - run: uv run ruff check .
```

## Migration Guides

### From pip
```bash
# Before: pip install -r requirements.txt
# After:
uv init
uv add -r requirements.txt
```

### From poetry
```bash
# Before: poetry install
# After: uv already reads pyproject.toml
uv sync
```

### From pip-tools
```bash
# Before: pip-compile && pip-sync
# After:
uv lock && uv sync --frozen
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `uv init` | Initialize project |
| `uv add PKG` | Add dependency |
| `uv add --dev PKG` | Add dev dependency |
| `uv remove PKG` | Remove dependency |
| `uv sync` | Install all deps |
| `uv sync --frozen` | Install exact (CI) |
| `uv lock` | Create/update lockfile |
| `uv run CMD` | Run in venv |
| `uv venv` | Create venv |
| `uv python install` | Install Python |
| `uv python pin` | Pin Python version |
| `uv cache clean` | Clear cache |

## Best Practices

1. Always use `uv run` instead of activating venv
2. Commit `uv.lock` to git
3. Use `--frozen` in CI for reproducible builds
4. Pin Python version with `.python-version`
5. Separate dev deps from production deps
6. Use workspaces for monorepos
7. Export `requirements.txt` for compatibility when needed
