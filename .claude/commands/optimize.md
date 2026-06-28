---
name: optimize
description: Review Claude Code and shared agent harness configuration and propose efficiency or portability optimizations.
argument_hint: [focus area: hooks, permissions, plugins, all]
allowed_tools:
  - Read
  - Bash
  - Grep
  - Glob
  - Edit
  - Write
---

<use_parallel_tool_calls>
Read and analyze files in parallel batches. Group related checks together.
</use_parallel_tool_calls>

# Optimize: Claude Code Harness Efficiency Review

Audit the Claude Code configuration for performance bottlenecks, redundant work, missing permissions, and dead config. Produce a prioritized report with concrete fixes.

## Focus Area

`$ARGUMENTS` — if provided, narrow the review to that area. Valid focus areas:

- `hooks` — hook execution overhead, redundant firings, matcher scope
- `permissions` — permission allowlist gaps causing frequent prompts
- `plugins` — disabled/unused plugins, startup cost
- `all` (default if no argument) — full audit

## Audit Dimensions

### 0. Usage Data Collection

Gather empirical data on what commands and tools consume the most resources:

```bash
rtk gain --history
```

This shows command frequency and token savings. Use it to identify:
- **Heavy hitters**: Commands called most often that could use cheaper models (`model: sonnet` in frontmatter)
- **Unproxied commands**: Frequently-used CLI tools not yet routed through RTK
- **Permission prompt tax**: Commands that appear often but aren't in the allowlist

Also run the built-in `/status` command output if available in context to cross-reference skill/plugin usage percentages.

For any command or skill consuming >10% of usage:
1. Check if it has `model:` frontmatter — if missing, it runs on the session model (Opus)
2. Assess whether the work is mechanical (classify, format, template) vs. requires reasoning
3. Mechanical work should use `model: sonnet`; only keep Opus for complex analysis
4. Check the skill/command body size — can it be condensed without losing spec fidelity?

### 1. Hook Overhead Analysis

Read `~/.claude/settings.json` hooks section. For each hook registration:

1. **Frequency**: How often does this fire? (PreToolUse fires on EVERY tool call; SessionStart fires once)
2. **Cost**: What does the script do? (spawns node/python? reads filesystem? makes HTTP calls?)
3. **Matcher scope**: Is the matcher overly broad? (e.g., firing on Bash when only Edit matters)
4. **Redundancy**: Does the same script register on multiple events unnecessarily?
5. **Fail mode**: Does it fail-open or fail-closed? What's the timeout?

Read each script in `~/.claude/hooks/scripts/` and `~/.claude/agent-flow/` to assess actual work done.

Flag:
- Scripts that spawn interpreters (node, python) on hot paths (PreToolUse, PostToolUse)
- Matchers that include `Bash` when the hook only cares about file mutations
- Scripts with side effects that never get read (log files, temp files)
- Hooks with timeouts longer than necessary for their actual work

### 2. Permission Allowlist Gaps

Read the `permissions.allow` array from `~/.claude/settings.json`.

Cross-reference against common command patterns:
- Git operations: status, branch, log, diff, fetch, checkout, push, commit, pull, rev-list, ls-remote, rev-parse, show, remote, symbolic-ref, merge, rebase, stash, tag
- GitHub CLI: pr (list/create/view/merge/edit), api, run (list/view), issue
- Build tools: just, make, cargo, go, npm, pnpm, yarn, pip, poetry
- Search/nav: find, ls, wc, grep, rg, sg, fd, tree, file, stat, head, tail
- Utilities: date, python3, jq, yq, sed, awk, sort, uniq, tr, cut, basename, dirname
- Mise: ls, search, use, install, current
- RTK: gain, discover, --version

Also check `~/.claude/logs/tool-failures.log` for patterns — commands that failed due to permission denial or that indicate frequent use.

Check project-level settings in `~/.claude/projects/*/settings.json` for project-specific allowlists that could be promoted to global.

### 3. Plugin Audit

From `enabledPlugins` in settings.json:
- Count enabled plugins and assess startup cost
- Check for disabled plugins still listed (should be removed entirely)
- Look for plugins that overlap in functionality
- Verify marketplace sources are still valid

### 3a. Skill Invocation Policy Audit

Audit `~/.agents/skills/*/SKILL.md` and any adjacent `agents/openai.yaml` files.
Classify each active skill as one of:

- **Procedural**: user-run workflows, interactive interviews, migrated slash commands, or procedures that should run only when explicitly invoked (for example, `git-commit`, `optimize`, `grilling`).
- **Ability**: model-invoked capabilities or domain rules the agent should automatically apply when the task matches (for example, code review standards, docs lookup, platform-specific implementation guidance).

For procedural skills, check for Codex metadata:

```yaml
policy:
  allow_implicit_invocation: false
```

Flag procedural skills without that policy. Do not claim this removes the skill from context; it only blocks implicit invocation. If a rarely used procedural skill should not appear in Codex's initial skill list at all, recommend disabling it with `[[skills.config]] enabled = false` in `~/.codex/config.toml` or moving it out of scanned skill paths.

Do not recommend creating a separate `classify-skill` skill unless the rubric is reused by multiple workflows. If created for model use, it is an ability; if exposed only as a user-run command, it is procedural.

### 3b. Harness Portability Audit

When optimizing shared skills or porting harness features between Claude, Codex, OpenCode, Pi, Antigravity, and Cursor, read `~/.agents/skills/optimize/references/agent-harness-portability.md`.

Audit these points:

1. Classify each skill as **procedural** or **ability** before mapping metadata.
2. Keep portable `SKILL.md` frontmatter minimal: `name` and `description` first. Treat fields such as `allowed-tools`, `disable-model-invocation`, `paths`, model hints, and UI metadata as harness-specific unless the target's primary docs confirm support.
3. Put Codex-specific behavior in `agents/openai.yaml`, especially `policy.allow_implicit_invocation` and `dependencies.tools`.
4. Front-load skill descriptions with the trigger and boundary so shortened skill lists still classify correctly.
5. Move long details into `references/`, deterministic repeat work into `scripts/`, and output resources into `assets/`.
6. Record unsupported or unverified harness metadata as an adapter gap instead of copying stale keys across tools.
7. When porting research changes current agent configuration facts, update `ATTRIBUTE_MAPPINGS` in `scripts/agent-harnesses.py`, regenerate `docs/agent-harnesses.*`, and update `~/.agents/skills/optimize/references/agent-harness-portability.md` in the same change.

### 4. MCP Server Efficiency

Check `.mcp.json` files for:
- Servers with high timeout values
- Servers that are rarely used but always connected
- Missing servers that would reduce tool calls (e.g., Context7 for docs)

### 5. Context Budget

Assess total context consumed by always-loaded config:
- `~/.claude/CLAUDE.md` + `@`-included files
- `~/.claude/rules/*.md` (all rules load on every session)
- Project CLAUDE.md files
- SessionStart hook output

Flag rules that are:
- Redundant with system behavior (already the default)
- Too verbose (could be condensed)
- Rarely applicable (should use `paths:` frontmatter to conditionally load)

### 6. Auto-Format Efficiency

If an auto-format hook exists, check:
- Does it run the minimal formatter for the specific file type?
- Does it run expensive operations (formatting ALL files) on single-file changes?
- Are formatter paths hardcoded or dynamically resolved?

## Output Format

```markdown
## Harness Optimization Report

### Critical (fix immediately — saves seconds per tool call)
| # | Issue | Impact | Fix |
|---|-------|--------|-----|
| 1 | ... | ~Xs per tool call | ... |

### High (fix soon — saves minutes per session)
| # | Issue | Impact | Fix |
|---|-------|--------|-----|

### Low (nice to have)
| # | Issue | Impact | Fix |
|---|-------|--------|-----|

### Already Optimal
- [list things that are well-configured]
```

After presenting the report, ask:
> Which optimizations would you like me to implement? (numbers, "all", or "none")

Then implement the selected fixes, verifying JSON validity after settings.json changes.
