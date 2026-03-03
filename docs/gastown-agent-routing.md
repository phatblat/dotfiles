# Gastown Agent Routing Policy

This runbook documents the default routing policy to reduce Codex/Claude usage
by shifting low-risk work to Gemini.

## Live Rig Policy

Low-risk rigs use Gemini for `witness` and `refinery`:

- `forge`
- `l8r`
- `mintlify_docs`
- `dql_browser`

Apply or re-apply:

```bash
just gt-agent-policy-apply
```

Show current policy:

```bash
just gt-agent-policy-show
```

## Smart Sling Command

Use `gt-sling-smart` for new work dispatches instead of raw `gt sling`.

Wrapper behavior:

- If `--agent` is passed, it is respected.
- If risk is `low`, routes to `gemini`.
- If risk is `high`, routes to `codex`.
- If no explicit risk:
  - high-risk keywords route to `codex`
  - low-risk keywords route to `gemini`
  - low-risk rig targets route to `gemini`
  - otherwise route to `codex`

Keywords are tuned for current usage management and can be updated in:

- `~/scripts/gt-sling-smart`

## Commands

Dispatch with automatic routing:

```bash
just gt-sling-smart dx-123 ditto_devx --merge=local
```

Force low-risk routing:

```bash
just gt-sling-smart dx-123 ditto_devx --risk low --merge=local
```

Preview routing decision:

```bash
just gt-sling-smart-dry-run dx-123 ditto_devx --merge=local
```

## Notes

- Current defaults:
  - `GT_SAFE_AGENT=gemini`
  - `GT_RISKY_AGENT=codex`
- You can override with env vars per shell/session.
