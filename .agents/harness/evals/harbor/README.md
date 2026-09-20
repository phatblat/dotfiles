# Harbor Evals for Shared Agent Harness

This directory contains Harbor eval tasks for testing the shared agent harness structure and behavior.

## Installation

Harbor is managed via mise as a pipx-installed Python tool. Install it with:

```bash
# Via mise (preferred - reads version from .config/mise/config.toml)
mise install pipx:harbor

# Or directly via uv tool (pinned to match mise)
uv tool install harbor==0.23.0
```

After installation, verify Harbor is available:

```bash
harbor --version
```

## Running Evals

Run all Harbor evals for the harness:

```bash
# From repo root
harbor run .agents/harness/evals/harbor/

# Or from this directory
cd .agents/harness/evals/harbor
harbor run .
```

Run a specific eval task:

```bash
harbor run .agents/harness/evals/harbor/harness-structure/
```

## Available Evals

### harness-structure/

A Harbor task directory that validates the shared agent harness structure:

**Structure:**
- `task.toml` - Task configuration
- `instruction.md` - Task description and requirements
- `tests/test_structure.sh` - Verification script

**What it checks:**
- Required files (README.md, instructions.md)
- Required directories (adapters/, commands/, agents/, hooks/)
- Content verification (non-empty files, inventory counts)
- At least one adapter exists

This eval runs locally with no external dependencies.

## Adding New Evals

Harbor tasks are directories with:

```
task-name/
├── task.toml           # Task configuration
├── instruction.md      # Task description
└── tests/              # Test scripts
    └── test_*.sh
```

Create new tasks with `harbor task init <name>` or by copying the structure above.

See [Harbor documentation](https://docs.harborframework.com/) for full task format details.
