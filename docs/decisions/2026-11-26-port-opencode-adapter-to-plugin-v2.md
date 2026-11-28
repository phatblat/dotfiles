# Port the opencode adapter to the V2 plugin API

## Issue

opencode 2.x replaced the V1 plugin API, and the generated ness guard for opencode is still a V1 plugin. `.config/opencode/plugins/harness.ts` default-exports a V1 `Plugin` function (declared at line 51, exported at line 87) whose hooks object runs the guard from `tool.execute.before` (line 60). The installed 2.4.1 binary contains no occurrence of `tool.execute.before`, contains the loader error string `failed to load plugin`, and appears to require a default export shaped `{id, effect|setup}`. The drift ledger first records a 2.x version on 2026-10-26 (`1.19.4` to `opencode v2.1.4` in `docs/harness/drift.md`), so opencode has probably run without ness since then.

Runtime rejection of the V1 plugin has not been observed. It is inferred from the loader's error string and the absence of `tool.execute.before`. The parity probe cannot tell either way: `scripts/harness_capabilities.py:896` only greps the plugin file for `\bness\b`, so the `hooks.safety` opencode cell still reads `aligned`.

Two gaps travel with the port:

- `bash_rules("opencode")` in `scripts/harness_policy.py` has no caller outside the snapshot test, and `render_opencode_config()` hard-codes the bash rules, so `.config/opencode/opencode.jsonc` does not carry the `[approval]` baseline.
- V1 leftovers remain: V1-shaped config keys in `opencode.jsonc` (not yet identified against the V2 config guide), `.config/opencode/tui.json` (a single `plugin` entry), and the `@opencode-ai/plugin` `1.19.5` pin in `.config/opencode/package.json`.

Findings L1, L17, and L29 of the [2026-11-26 flywheel findings](../flywheel/findings/2026-11-26.md) hold the evidence. The subagent `bash: ask` override of the global `sudo *: deny` rule (L2) is handled separately by a pending generator patch and is not part of this decision.

## Status

This is a proposal that is **awaiting review**.

## Assumptions and Constraints

- `scripts/agent-harnesses.py` and `scripts/harness_policy.py` are control-plane files: an agent delivers patches and a human applies them.
- The port keeps the guard's fail-closed behaviour (a guard error or unparseable output is a deny) and its 5,000 ms timeout.
- The V2 plugin API is unverified. The V2 tool names (`shell` and the patch tool) and the way a hook signals a denial were seen only as strings in the 2.4.1 binary.
- The 2.4.1 binary's migration notice says V1 config files are intended to remain compatible, that the only intentional breaking changes are the server API and the plugin API, and that config conversion is optional.
- Usage data cannot inform the port: the 30-day session scan lists one opencode database, and the findings cite no opencode friction count, so nothing can be measured beforehand.
- In the audit's single run, `opencode debug config` exited 0 and printed two config objects with no plugin-load output. The existing probe only checks its exit code, so it cannot serve as the load probe.

## Argument

Port the plugin to V2 and replace the probe with one that fails when the plugin does not load. **Chosen.** It restores the guard and makes the registry report the truth: the gap went unnoticed because the present probe proves the file mentions ness, not that opencode loads it.

Keep the V1 plugin and wait for upstream compatibility. **Rejected.**

Drop opencode support. **Rejected.**

## Architectural Decision

1. Port `render_opencode_plugin()` to the V2 `{id, setup}` shape, guarding the V2 shell, write, edit, and patch tools. The V2 plugin guide is read first, and the tool names and denial signal are taken from it, not from the binary strings.
2. Replace the `hooks.safety` opencode probe with one that fails when the plugin does not load.
3. Identify the V1 config keys against the V2 config guide, then emit V2 keys from `render_opencode_config()` and `render_opencode_agent()`, delete `.config/opencode/tui.json`, and retarget or drop the `@opencode-ai/plugin` pin in `.config/opencode/package.json`. Because conversion is optional, this clause is hygiene and may be deferred without blocking clauses 1 and 2.
4. Render `permission.bash` in `render_opencode_config()` from `bash_rules("opencode")`, and the `edit`, `external_directory`, and `webfetch` permissions from the three `OPENCODE_*` mode constants. This replaces the present 16 hard-coded rules (8 allow, 7 ask, 1 deny) with the full `[approval]` baseline of 117 (115 allow, 1 ask, 1 deny). The catch-all `"*": "ask"` default in `permission.bash` must stay, because `bash_rules("opencode")` does not emit one. The existing `find` action carve-outs and new `ask` rules for `rg --pre` and `git diff --output` must stay effective under last-match-wins. This clause lands only after clauses 1 and 2, so the wider allowlist never ships while the guard is not loading.
5. Until clauses 1 and 2 land, the `hooks.safety` opencode cell is set to `partial` and opencode is not launched in any auto-approve mode. The 2.4.1 flag table names three: `auto`, `yolo`, and `dangerously-skip-permissions`.

## Positions

- **Keep the V1 plugin and wait for upstream compatibility.** Rejected: the binary's own migration notice calls the plugin API break intentional and names no compatibility layer, and waiting leaves opencode unguarded behind an `aligned` cell.
- **Drop opencode support.** Rejected: it closes the gap by removing the thing guarded, which is the owner's call and not a repair. It stands unless the owner retires the harness, which [2026-11-08-remove-cursor-and-grok-harness-support](./2026-11-08-remove-cursor-and-grok-harness-support.md) shows is an available choice.
