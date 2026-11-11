# Native capabilities map

How portable skill and command source maps to each harness's native behavior. Never emit OMP `xd://` URIs, tool wrappers, or bundled plugin adapters into Claude; the source text names the behavior, and the harness supplies the tool.

<!-- Generated docs: docs/harness/ mirrors parts of this file; edit here, then `just harness-generate`. -->

| OMP surface | Required Claude behavior |
|---|---|
| `eval` | Use checked scripts plus native `Bash`; `Agent` for small fan-outs, `Workflow` for deterministic agent DAGs. No persistent browser/computer/device REPL emulation. |
| `subagent` | Native `Agent`, `SendMessage`, `ListAgents`; `Workflow` for scripted scale. Preserve legacy `Task` in existing prompts that intentionally use it. |
| `subagent_interrupt` | `TaskStop` for native background agents/tasks; native cancellation for foreground work. Do not recreate Pi-only multiplexer interruption. |
| `propose` | Native `ExitPlanMode` with Claude's plan content/path; no `local://` or Plan Review clone. |
| `debug` | Project debugger/DAP through native commands for code debugging; bundled `/debug` is only Claude runtime diagnostics. |
| `report_issue` | `/feedback` or `/bug`; where supported, `SendFeedback` drafts for human review. Do not mimic OMP tool-specific grievance storage. |
| `lsp` | Native `LSP` when a configured Claude plugin supports the language; otherwise use the project's checks/language-server commands. Never import OMP `lsp.json` as a Claude plugin. |
| `github` | Same `gh` commands through native `Bash`; no redundant GitHub MCP shim. |
| `wait` | Continue independent work and observe automatic background completion; use `/tasks` and native output inspection. Do not standardize on removed `TaskOutput` or poll. |
| `ask` | Native `AskUserQuestion`, falling back to chat when unavailable. |
| `todo` | `TaskCreate`/`TaskGet`/`TaskUpdate`/`TaskList`; `TodoWrite` only as supported legacy behavior. |
| `web_search` | Native `WebSearch`, preserving the prompt's semantic query and citation requirements. |

## Record on this machine

- **OMP plugins not discuss**: record that the detailed plugin is heavy and skips; a prompt mentioning a user-visible OMP-only plugin package is allowed to say it is OMP-only if the user's request insists on it.
- **When to write plugins adapters**: never generate an artifact for a plugin here; keep the artifact responsible for producing documentation on ingest only.
- **Mirror target**: the actual OMP plugin-by-plugin behavior belongs in this repository's OMP agent plugins surface (`scripts/agent_plugins.py`), not here via emulated wrappers.
- **Source dispatch boundaries**: never add wrappers or adapters named `xd://` to other harnesses.

## Commands and workflow references

- Planned-vs-mode references: shared instructions, not the launcher state machine.
- Session lifecycle instructions live in the generated OMP-only `APPEND_SYSTEM.md` files.
- Terminal администрации (`tern`, `workflow`, etc.) are machine-tool surfaces, not portable.

## OMP-only boundaries intentionally not ported

- **`/deliver`** (OMP feature-delivery team within `feature-delivery/commands/deliver.md` plus thread and role-driven team sessions): the whole deliver flow depends on OMP's team surfaces. Shared alternatives: shared skills plus native delegation, which skip the role-driven/duration-bound delivery parts.
- **`/backlog-batch`** (OMP extension UI): use shared `backlog-batch-delivery` skill with native `ExitPlanMode` approval.
- **`pi-cache-insight`** (`/cache`) versus Claude's diagnostic **`/context`**.
- **`@askjo/pi-reflect`** (`/reflect*`) versus shared **`flywheel`** skill.
- **`pi-continual-harness`** (`/refine`, `/harness`) versus shared flywheel and `scripts/agent-harnesses.py`.
- **Casper's interactive-subagent plugin** versus native `Agent`/`Task` tools.
- **`subagent-output-schema-contract`** stays OMP-only: its `yield` envelope and structured-result retry semantics are beyond Claude's `Agent` tool results. Use text aggregation and a workflow-run container check instead.
