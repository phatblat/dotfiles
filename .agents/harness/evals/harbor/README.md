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

Run Harbor evals for the harness:

```bash
# Via just recipe
just harness-evals

# Or directly with Harbor
harbor run -p .agents/harness/evals/harbor/harness-structure -a nop
```

## Available Evals

### harness-structure/

A Harbor task that validates the shared agent harness structure.

**Task structure (Harbor 0.23.0 format):**
```
harness-structure/
├── task.toml                    # Task configuration (schema_version 1.4)
├── instruction.md               # Task description
├── environment/
│   ├── Dockerfile              # Build context
│   └── harness/                # Harness snapshot (regenerate on changes)
│       ├── README.md
│       ├── instructions.md
│       ├── adapters/
│       ├── commands/
│       ├── agents/
│       └── hooks/
├── tests/
│   └── test.sh                 # Verification script (writes reward.txt)
└── solution/
    └── solve.sh                # No-op solution
```

**What it verifies:**
- Required files (README.md, instructions.md)
- Required directories (adapters/, commands/, agents/, hooks/)
- Content validation (inventory section, commands count)
- At least one adapter exists

**Regenerating the harness snapshot:**

When the shared harness changes, update the snapshot in `environment/harness/`:

```bash
cd .agents/harness
cp -r README.md instructions.md adapters commands agents hooks \
      generated-paths.json self-improve-policy.json \
      evals/harbor/harness-structure/environment/harness/
```

Exclude `evals/` to avoid recursion.

## Adding New Evals

Create new Harbor tasks with:

```bash
harbor task init phatblat/<task-name> --no-pytest
```

Task name must be in `org/name` format. See [Harbor documentation](https://docs.harborframework.com/) for full details.
