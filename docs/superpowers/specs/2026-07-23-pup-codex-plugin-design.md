# Pup Claude/Codex Plugin Parity — Design Spec

## Goal

Make Pup available and enabled in the two daily agent harnesses:

- Re-enable the existing `pup@datadog-pup` Claude plugin.
- Install and enable the complete Pup plugin for Codex from the upstream
  `DataDog/pup` repository, pinned to the `v1.6.6` release.
- Extend the tracked agent-harness inventory so installed, enabled, and version
  drift between Claude and Codex is visible.

## Dependency

The approved Pup mise migration must complete first so every installed Datadog
skill resolves a working mise-managed Pup 1.6.6 binary.

## Claude

Re-enable the already-installed user-scoped plugin:

```bash
claude plugin enable pup@datadog-pup --scope user
```

Do not reinstall or upgrade it. Add `DataDog/pup` to the tracked
`extraKnownMarketplaces` map in `.claude/settings.json` if the enable command
does not persist the already-known marketplace there. Claude currently has
plugin version `0.25.0`; that version is reported as observed state rather than
normalized to Codex's upstream release tag.

## Codex

Register `DataDog/pup` as a native Codex Git marketplace pinned to `v1.6.6`,
then install `pup@datadog-pup` from that marketplace:

```bash
codex plugin marketplace add DataDog/pup --ref v1.6.6
codex plugin add pup@datadog-pup
```

The upstream plugin manifest exposes its complete `skills/` directory to
Codex. This avoids copying skill files into `.agents/skills` and keeps the
plugin tied to a reproducible upstream release.

## Installed Capabilities

Both harnesses expose these nine shared skills:

- `dd-apm`
- `dd-code-generation`
- `dd-debugger`
- `dd-docs`
- `dd-file-issue`
- `dd-logs`
- `dd-monitors`
- `dd-pup`
- `dd-symdb`

The full Codex plugin at marketplace tag `v1.6.6` additionally exposes:

- `dd-triage-flaky-test`
- `dd-unblock-pr`

Claude's existing plugin reports manifest version `0.25.0`; the Codex plugin
reports manifest version `0.62.0`. These manifest versions are independent of
the verified Codex marketplace checkout tag `v1.6.6`.

The separate `datadog@openai-curated` app remains uninstalled. Codex's
`features.apps` setting remains disabled because the Pup plugin is skill-based
and invokes the local CLI.

## Harness Inventory

Extend `scripts/agent-harnesses.py` with native plugin configuration discovery
for Claude and Codex. Generated artifacts read the tracked sources of truth:

- `.claude/settings.json`: `enabledPlugins` and `extraKnownMarketplaces`
- `.codex/config.toml`: `plugins` and `marketplaces`

Normalize their different schemas into a top-level `plugins` map. The generated
inventory covers every configured native plugin, not only Pup:

```json
{
  "plugins": {
    "claude": [
      {
        "id": "pup@datadog-pup",
        "enabled": true,
        "marketplace": "datadog-pup"
      }
    ],
    "codex": [
      {
        "id": "pup@datadog-pup",
        "enabled": true,
        "marketplace": "datadog-pup"
      }
    ]
  }
}
```

This split keeps generation deterministic on machines and in CI that do not
have Claude or Codex installed. Include configured plugin state in
`inventory --json`, `docs/agent-harnesses.json`, and
`docs/agent-harnesses.md`. The Markdown output shows a compact Claude/Codex
matrix over the union of configured plugin IDs so enabled, disabled, and
missing differences are visible in review diffs.

Extend `audit` with live native plugin discovery using:

```bash
claude plugin list --json
codex plugin list --json
```

The audit normalizes `id`, `version`, `installed`, `enabled`, and `scope`, then
compares observed state with the tracked configuration. It explicitly reports
configured/observed mismatches and makes the current Claude `0.25.0` versus
Codex `0.62.0` manifest-version difference visible without declaring it an
error.

Inventory and audit are visibility-only:

- It records differences without changing either harness.
- It does not require equal version strings because Claude and Codex report
  versions from different release channels.
- A missing CLI or failed JSON query produces an explicit unavailable audit
  state rather than silently presenting an empty plugin list.
- Other harnesses remain outside this first iteration.

## Tests

Add focused tests using temporary tracked-config fixtures and fake CLI
executables instead of relying on the developer machine's live plugin state.
Cover:

- Claude tracked-config normalization, including marketplace identity and
  disabled state.
- Codex tracked-config normalization, including marketplace identity and
  enabled state.
- Claude and Codex live schema normalization, including version, installed,
  enabled, and scope fields.
- Missing or failed live harness commands producing unavailable audit state.
- Pup appearing in both columns of the generated plugin matrix.

Regenerate tracked harness artifacts and review the diff. Because generated
harness artifacts are already stale on the baseline, accept the complete
deterministic output from `just harness-generate`; do not hand-edit generated
files.

## Failure Handling

If Codex marketplace registration succeeds but plugin installation or
validation fails, remove the incomplete `pup@datadog-pup` installation and the
`datadog-pup` marketplace. Leave the working mise Pup installation and Claude's
pre-existing plugin installed. Restore Claude to disabled only if re-enabling
it caused the failure.

The existing Nushell `nixtest` smoke failure is unrelated. The stale generated
harness artifacts and missing Antigravity plugin artifacts are baseline
failures that may be resolved incidentally by the required deterministic
regeneration; any remaining unrelated failures are reported without expanding
scope.

## Verification

- `mise which pup` resolves inside mise's installation root.
- `pup --version` reports `pup 1.6.6` in a fresh login shell.
- `claude plugin list --json` reports `pup@datadog-pup` enabled.
- `codex plugin marketplace list` includes `datadog-pup`.
- `codex plugin list --json` reports `pup@datadog-pup` installed and enabled.
- Claude exposes the nine shared `dd-*` skills.
- Codex exposes those nine plus `dd-triage-flaky-test` and `dd-unblock-pr`
  from the full upstream `v1.6.6` plugin.
- `python3 scripts/agent-harnesses.py inventory --json` reports Pup enabled in
  both tracked configurations.
- `python3 scripts/agent-harnesses.py audit --json` reports both observed Pup
  versions and no configured/observed enabled-state mismatch.
- Focused plugin and harness tests pass.
- Full lint passes; full tests introduce no failures beyond recorded unrelated
  baseline failures.

## Rollback

Disable Claude and remove the Codex plugin and marketplace:

```bash
claude plugin disable pup@datadog-pup --scope user
codex plugin remove pup@datadog-pup
codex plugin marketplace remove datadog-pup
```

Rollback does not uninstall Pup from mise.
