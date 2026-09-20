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
harbor run .agents/harness/evals/harbor/harness-structure.yaml
```

## Available Evals

### harness-structure.yaml

Validates that the shared agent harness has the expected directory structure:
- Required files (README.md, instructions.md)
- Required directories (adapters/, commands/, agents/, hooks/)
- Content verification (non-empty files, inventory counts)
- At least one adapter exists

This eval runs locally with no external dependencies and completes in under 30 seconds.

## Adding New Evals

Follow the Harbor task format:

```yaml
name: task-name
description: What this task verifies
version: "1.0"

environment:
  type: local
  working_directory: relative/path

instruction: |
  Clear description of what to verify or test.

verifier:
  type: script
  script: |
    #!/bin/bash
    # Verification script that exits 0 on success, non-zero on failure

timeout: 30
```

See [Harbor documentation](https://docs.harborframework.com/) for full task format details.
