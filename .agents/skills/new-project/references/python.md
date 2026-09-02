# Python (uv) Reference

## 1. Pin tools

```bash
mise use --pin just@latest python@latest uv@latest
```

## 2. `mise.toml`

After the pin step, append the `[deps.uv]` and `[settings]` blocks so the
final file reads:

```toml
[tools]
just = "<pinned>"
python = "<pinned>"
uv = "<pinned>"

# `mise deps` runs `uv sync` when pyproject.toml or uv.lock changes.
[deps.uv]

[settings]
# `[deps.*]` is experimental. Declaring it here means the project works without
# the developer's global mise config enabling it.
experimental = true
```

Then run `mise trust && mise fmt`.

## 3. Native init

Order is load-bearing — the interpreter preference must be in place before
anything creates `.venv`:

1. `uv init --package --name <name> --author-from git --vcs none --no-readme --no-pin-python --no-workspace`

   `--no-workspace` is required, not optional: without it, `uv init` walks up
   the directory tree to the nearest `.git` boundary looking for a workspace
   root, and silently joins whatever ancestor `pyproject.toml` it finds there
   — or fails outright if that file has no `[project]` table (verified: a
   dotfiles checkout at `~` with a bare `[tool.basedpyright]` `pyproject.toml`
   breaks every `uv init` run in any subdirectory that isn't yet its own git
   repo). A freshly scaffolded project must always be standalone.
2. Append to `pyproject.toml`:

   ```toml
   [tool.uv]
   # mise.toml pins the interpreter. Without `only-system`, uv downloads and binds
   # .venv to its own managed Python and the mise pin becomes decorative.
   python-preference = "only-system"

   [tool.ruff]
   line-length = 100
   src = ["src", "tests"]

   [tool.ruff.lint]
   select = ["E", "F", "I", "UP", "B"]

   [tool.mypy]
   python_version = "<pinned major.minor>"
   strict = true
   files = ["src", "tests"]

   [tool.pytest.ini_options]
   testpaths = ["tests"]
   ```

3. `uv add --dev mypy pytest ruff`
4. `uv sync`

## 4. Test

`tests/test_<module>.py` — a real behavioral test of the `main()` that
`uv init --package` generates:

```python
import pytest

from <module> import main


def test_main_greets(capsys: pytest.CaptureFixture[str]) -> None:
    main()
    assert "Hello from <name>!" in capsys.readouterr().out
```

`[tool.mypy] strict = true` covers `tests/` too (see `files` below), so the
test itself needs a full signature — an untyped `capsys` parameter or a
missing `-> None` return annotation fails `just typecheck`.

## 5. `.gitignore`

```gitignore
.venv/
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
.mypy_cache/
.ruff_cache/
.pytest_cache/
.coverage
htmlcov/
```

## 6. `justfile`

This is the canonical shape every other stack's template mirrors.

```just
set ignore-comments
set script-interpreter := ['bash', '-eu']
set unstable

[default]
_default:
    @just --list

#
# configuration group recipes
#

# Install pinned tools and sync the virtualenv
[group('configuration')]
deps:
    mise install
    mise deps

# Format source, mise config, and the justfile
[group('configuration')]
format:
    uv run ruff format .
    mise fmt
    just --fmt

# Remove build output, caches, and the virtualenv
[group('configuration')]
[script]
clean:
    set -euo pipefail
    rm -rf dist build .venv .pytest_cache .mypy_cache .ruff_cache
    find src tests -type d -name __pycache__ -prune -exec rm -rf {} +

# Report tools and dependencies with newer versions available
[group('configuration')]
outdated:
    -mise outdated --local --bump
    -uv lock --upgrade --dry-run

# Upgrade pinned tools and locked dependencies to their latest versions
[group('configuration')]
upgrade:
    mise upgrade --local --bump --yes
    uv lock --upgrade
    uv sync

#
# build group recipes
#

# Build the distributable package
[group('build')]
build:
    uv build

# Run the application
[group('build')]
run:
    uv run <name>

#
# checks group recipes
#

# Verify formatting without writing changes
[group('checks')]
format-check:
    uv run ruff format --check .
    mise fmt --check
    just --fmt --check

# Lint source with ruff
[group('checks')]
lint:
    uv run ruff check .

# Type-check with mypy
[group('checks')]
typecheck:
    uv run mypy

# Run every gate: formatting, lint, types, tests
[group('checks')]
check: format-check lint typecheck test

#
# tests group recipes
#

# Run the test suite
[group('tests')]
test:
    uv run pytest
```
