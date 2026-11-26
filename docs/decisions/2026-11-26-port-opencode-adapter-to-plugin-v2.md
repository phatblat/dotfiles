# Port the opencode adapter to the V2 plugin API

## Issue

opencode 2.x replaced the V1 plugin API, and the generated ness guard for opencode is still a V1 plugin. `.config/opencode/plugins/harness.ts` default-exports a V1 `Plugin` function (declared at line 51, exported at line 87) whose hooks object runs the guard from `tool.execute.before` (line 60). The installed 2.4.1 binary contains no occurrence of `tool.execute.before`, contains the loader error string `failed to load plugin`, and appears to require a default export shaped `{id, effect|setup}`. The drift ledger first records a 2.x version on 2026-10-26 (`1.19.4` to `opencode v2.1.4` in `docs/harness/drift.md`), so opencode has probably run without ness since then.

Runtime rejection of the V1 plugin has not been observed. It is inferred from the loader's error string and the absence of `tool.execute.before`. The parity probe cannot tell either way: `scripts/harness_capabilities.py:896` only greps the plugin file for `\bness\b`, so the `hooks.safety` opencode cell still reads `aligned`.

Two gaps travel with the port:

- `bash_rules("opencode")` in `scripts/harness_policy.py` has no caller, so the bash rules in `.config/opencode/opencode.jsonc` are not rendered from the `[approval]` baseline.
- V1 leftovers remain: the config keys the audit classed as V1 in `opencode.jsonc` (not checked here against a V2 schema), `.config/opencode/tui.json` (a single `plugin` entry), and the `@opencode-ai/plugin` `1.19.5` pin in `.config/opencode/package.json`.

Findings L1, L17, and L29 of the [2026-11-26 flywheel findings](../flywheel/findings/2026-11-26.md) hold the evidence. The subagent `bash: ask` override of the global `sudo *: deny` rule (L2) is handled separately by a pending generator patch and is not part of this decision.

## Status

This is a proposal that is **awaiting review**.

## Assumptions and Constraints

- `scripts/agent-harnesses.py` and `scripts/harness_policy.py` are control-plane files: an agent delivers patches and a human applies them.
- The port keeps the guard's fail-closed behaviour (a guard error or unparseable output is a deny) and its 5,000 ms timeout.
- The V2 plugin API is unverified. The V2 tool names (`shell` and the patch tool) and the way a hook signals a denial were seen only as strings in the 2.4.1 binary.
- Usage data cannot inform the port: the 30-day session scan lists one opencode database and no opencode guard observations, so nothing can be measured beforehand.
- `opencode debug config` exits 0 without loading plugins, so it cannot serve as the probe.

## Argument

Port the plugin and replace the probe with one that fails when the plugin does not load. **Chosen.** It is the only option that restores the guard and also makes the registry report the truth: the present gap went unnoticed because the probe proves the file mentions ness, not that opencode loads it.

Keep the V1 plugin and wait for upstream compatibility. **Rejected.** Waiting leaves opencode unguarded for an open-ended period behind an `aligned` cell.

Drop opencode support. **Rejected** unless the owner retires the harness: it removes the gap by removing the harness, which is the owner's call and not a repair.

## Architectural Decision

1. Port `render_opencode_plugin()` to the V2 `{id, setup}` shape, guarding the V2 shell, write, edit, and patch tools. The V2 plugin guide is read first, and the tool names and denial signal are taken from it, not from the binary strings.
2. Replace the `hooks.safety` opencode probe with one that fails when the plugin does not load.
3. Emit V2 config keys from `render_opencode_config()` and `render_opencode_agent()`, delete `.config/opencode/tui.json`, and retarget or drop the `@opencode-ai/plugin` pin in `.config/opencode/package.json`.
4. Wire `bash_rules("opencode")` and the three `OPENCODE_*` mode constants into `render_opencode_config()`. Rules are emitted in an order that keeps `find * -delete*` after `find *` under last-match-wins, and `rg * --pre*` and `git diff* --output*` are added as `ask`.
5. Until clauses 1 and 2 land, the `hooks.safety` opencode cell is set to `partial` and `opencode --auto` is not run.

## Positions

- **Port to V2 with a load-proving probe.** Chosen: see Argument.
- **Keep the V1 plugin and wait for upstream compatibility.** Rejected: the 2.4.1 binary carries no V1 hook name and a V1-to-V2 migration notice that points at a plugins guide, so the break reads as intentional and no compatibility layer is in sight.
- **Drop opencode support.** Rejected unless the owner says the harness is retired. [2026-11-08-remove-cursor-and-grok-harness-support](./2026-11-08-remove-cursor-and-grok-harness-support.md) shows that retiring a harness is an available choice.
