---
paths:
  - "**/*.py"
  - "pyproject.toml"
  - "uv.lock"
---

# Python Conventions

## Tooling
- Package manager: `uv` (never pip/poetry)
- Formatter + linter: `ruff` (never black/isort/flake8)
- Tests: `pytest` with `uv run pytest`
- Type checking: `mypy` or `pyright`

## Code Style
- Type hints on all function signatures (params + return)
- `from __future__ import annotations` for modern syntax
- Prefer `pathlib.Path` over `os.path`
- Prefer `dataclass` or `pydantic.BaseModel` over plain dicts
- Async: use `asyncio` + `async/await`, never threading for I/O

## Project Setup
```bash
uv init project-name && cd project-name
uv add <dep>          # runtime
uv add --dev <dep>    # dev only
uv run pytest         # run tests
uv run ruff check .   # lint
uv run ruff format .  # format
```

## Testing Patterns
- File naming: `test_<module>.py` or `tests/test_<module>.py`
- Use `pytest.fixture` for setup, `pytest.mark.parametrize` for variants
- Assert with plain `assert`, not `self.assertEqual`
- Mock external services, never real APIs in tests

## Validation Command
After writing Python code, always suggest: `uv run ruff check . && uv run pytest`
