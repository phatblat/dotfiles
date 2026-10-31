---
name: implement-plan
description: "Execute a reviewed implementation plan step by step with verification and standards review"
argument-hint: "<path-to-plan.md>"
disable-model-invocation: true
---

<!-- Adapted from mkrtchian/spec-driven-dev v1.11.0 (https://github.com/mkrtchian/spec-driven-dev), MIT License, Copyright (c) 2026 Roman Mkrtchian. See LICENSE in this directory. -->

## Host notes

This workflow runs on every host in the shared agent harness (Claude Code, OMP, Codex, OpenCode, Cursor, Grok, Antigravity).

- `$ARGUMENTS` is the text the user passed when invoking this skill. Treat it as empty when nothing was passed.
- Each `Dispatch(...)` block below starts one fresh subagent that runs the named specialist (`agent=`), with `prompt` as its entire task and `description` as its label. Wait for it to finish and act only on its final report. Map the block to the host's subagent tool:
  - Claude Code: the subagent tool (`Task`/`Agent`) with `subagent_type` set to the `agent` value and `model="opus"`.
  - OMP: the `task` tool with one task item whose `agent` is the `agent` value and whose `task` text is the `prompt`.
  - Codex and other hosts with named custom agents: spawn the custom agent with that name.
  - A host without named agents: spawn a general-purpose subagent whose prompt begins "Read `~/.agents/harness/agents/<agent>.toml` and follow its `developer_instructions` as your complete role.", followed by the `prompt` text.
- `model="opus"` asks for the strongest available model. On a host that cannot choose a model per dispatch, use the session's model.
- When this skill says to ask the user, use the host's question tool if it has one (`AskUserQuestion` in Claude Code, `ask` in OMP). Otherwise ask in chat and wait for the answer.

## Objective

Execute a reviewed plan through its implementation steps. Each step gets a dedicated implementer agent, followed by a step hardener that verifies completeness and fixes emergent issues. After all steps, a fact check against live sources, a standards review and a final review close the loop.

## Context

The plan to implement is given as `$ARGUMENTS`. It may be a direct path, a natural-language reference (e.g. "the plan we just wrote"), or empty.

## 0. Validate and resolve the plan path

Resolve `$ARGUMENTS` to a concrete plan file:

1. If `$ARGUMENTS` is a path to an existing file, use it directly.
2. If `$ARGUMENTS` is empty or is a phrase rather than a path (e.g. "the plan we just wrote", "the latest one"), interpret it and locate the intended plan among `plans/*.md` (for "the latest" or "the one we just wrote", the most recently modified `plans/*.md` file). This is a guess that launches a full implementation run, so state the resolved path back to the user and confirm before proceeding.
3. If it cannot be resolved to a single file (`$ARGUMENTS` looks like a path but the file does not exist, `plans/` is empty or absent, nothing matches, or several plausibly match), ask the user (with the host's question tool if it has one, such as `AskUserQuestion` in Claude Code or `ask` in OMP): "Which plan file should I implement?" with a hint to provide the path.

From this point on, `$PLAN_PATH` refers to this resolved plan file. Use `$PLAN_PATH`, not the raw `$ARGUMENTS`, everywhere below.

Read the plan file at `$PLAN_PATH`. If it doesn't exist, error and stop.

Check that the plan has an `## Implementation steps` section. If not, tell the user: "This plan has no implementation steps. Run the `write-plan` skill first, or add an `## Implementation steps` section manually."

Record the current git HEAD before any changes:
```bash
BASELINE_SHA=$(git rev-parse HEAD)
```

`$UNVERIFIED_FACTS` starts empty. Steps accumulate into it (§1a), and §2 passes it to the fact check.

`$RELAY_FACTS` starts empty. §2 records into it the fact check's `NEEDS A FRESH IMPLEMENTER` items, §2a hands them to an implementer, and §2b verifies the result.

Parse the implementation steps from the plan. Each step starts with `### Step N:` or `**Step N:`.

## 1. Execute steps

For each step in order:

### 1a. Implement (fresh sub-agent)

Display:
```
--- Step N: [step title] ---
Spawning implementer...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-implementer",
  model="opus",
  description="Implement step N",
  prompt="
    ## Step to implement

    {content of step N from the plan}

    ## Plan file path

    $PLAN_PATH
  "
)
```

Handle the implementer's exit state:

- **IMPLEMENTATION COMPLETE**: record any `Unverified external value:` bullets the implementer reported in its `Deviations from plan` section, accumulating them across steps into `$UNVERIFIED_FACTS`. Keep each entry to the value, the file it landed in, and the one-line reason: nothing else from the implementer's report enters the orchestrator. Then proceed to hardening (§1b). This applies to every implementer invocation, the extra implementer spawned on the §1b fix path included. The third invocation, the relay implementer of §2a, reports the same bullets to a different destination: they go into the §2b prompt, not into `$UNVERIFIED_FACTS`, which §2 has already consumed by then.
- **IMPLEMENTATION BLOCKED**: do NOT spawn the hardener. Present the block to the developer (what blocks, what was tried, state of the tree) and ask how to proceed. Keep it open-ended: the developer may rework the plan and retry the step, unblock the tree manually, or stop. Do not offer a skip-and-continue: a blocked step usually leaves later dependent steps unbuildable.

### 1b. Step hardening (fresh sub-agent)

Display:
```
--- Step N: Hardening ---
Verifying and fixing if needed...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-step-hardener",
  model="opus",
  description="Harden step N",
  prompt="
    ## Step that was supposed to be implemented

    {content of step N from the plan}

    ## Plan file path

    $PLAN_PATH
  "
)
```

Handle the result:

- **STEP COMMITTED**: Continue to next step.
- **STEP COMMITTED WITH FIXES**: Note the fixes applied, continue to next step.
- **ISSUES FOUND**: No commit was made. Present the issues to the user. Findings travel verbatim wherever they go, to the developer here and to the implementer below: never drop, merge, reword, or summarize one. If this step has already come back with `ISSUES FOUND` earlier in this run, say so, and name which findings the new report raises again and which it does not repeat. A finding that is not repeated is not proof it was fixed: this hardener is a fresh agent that never saw the earlier report. Ask: "Fix these issues, skip them, or stop implementation?"
  - If fix: spawn a fresh implementer at the findings. This is one of the workflow's two relays of a pass's conclusions to another pass to apply, the other being the fact-check relay of §2a. Both have the same shape: a fresh implementer applies the conclusions, and a fresh pass verifies the result behind it, because the prose handover still loses something. Here that verifying pass is a fresh hardening run.

    Display:
    ```
    --- Step N: Fixing findings ---
    Spawning implementer...
    ```

    ```
    Dispatch(
      agent="sdd-implementer",
      model="opus",
      description="Address step N findings",
      prompt="
        ## Step that was implemented

        {content of step N from the plan}

        ## Plan file path

        $PLAN_PATH

        ## State of the tree

        This step is already implemented and left uncommitted. A hardening pass reviewed it, applied the fixes it could, and would not commit the result. Run `git diff` and `git diff --cached` before editing anything: the tree carries the implementer's work plus the hardener's fixes, keep both. Address the findings below rather than reimplementing the step, and do not redo the step's TDD decision: add or amend tests only where a finding calls for it.

        ## Findings to address

        {the hardener's ISSUES FOUND items, verbatim}
      "
    )
    ```

    If that implementer returns `IMPLEMENTATION BLOCKED`, handle it exactly as §1a: present the block to the developer and ask how to proceed, and do NOT re-harden a blocked tree. Otherwise (`IMPLEMENTATION COMPLETE`), re-harden.
  - If skip: discover the project's commit conventions using the same priority order as `~/.agents/harness/agents/sdd-standards-enforcer.toml` "Discover commit conventions" (project instruction-file rules first, then a commit skill or command, then commitlint/commitizen config, else standard conventional commits). Stage only the changed files by name (never `git add -A` or `git add .`), commit following those conventions, and never use `git commit --no-verify`: pre-commit hooks must run. Then continue to next step.
  - If stop: go directly to the summary

Record the step result (committed / committed with fixes / issues found + action taken).

## 2. Fact check (fresh sub-agent)

Display:
```
--- Fact Check ---
Verifying the diff's external facts against live sources...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-fact-checker",
  model="opus",
  description="Check external facts",
  prompt="
    Plan file: $PLAN_PATH
    Baseline: $BASELINE_SHA

    Unverified external values reported during implementation:
    $UNVERIFIED_FACTS
  "
)
```

If no implementer reported any, say so explicitly in that section rather than omitting it.

Handle the result:

- **FACTS VERIFIED**: Continue.
- **FACTS CORRECTED**: Note the corrections applied, continue.
- **ISSUES FOUND**: Present the issues to the user and ask how to proceed. Present any `NEEDS A FRESH IMPLEMENTER` items as part of what the developer sees rather than routing them: this state means the tree is in a condition no automated correction should build on.

On `FACTS VERIFIED` or `FACTS CORRECTED`, read the report's `NEEDS A FRESH IMPLEMENTER` section before continuing. If it reads "none", go to §3 as usual. If it carries items, record them verbatim into `$RELAY_FACTS` and go to §2a instead. Keep each entry to the true value, the source that settles it, and the file the false value landed in: nothing else from the fact check's report enters `$RELAY_FACTS`.

## 2a. Relay to a fresh implementer

Only when `$RELAY_FACTS` is non-empty.

Display:
```
--- Fact Check: Applying corrections ---
Spawning implementer...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-implementer",
  model="opus",
  description="Apply fact-check corrections",
  prompt="
    ## Corrections to apply

    {$RELAY_FACTS, verbatim}

    These corrections are the entire scope of your task. The plan file below is context for reading the code around them, nothing more: do not implement the plan.

    ## Plan file path

    $PLAN_PATH

    ## State of the tree

    Every implementation step is committed, and the fact-check pass that produced the corrections above already committed the ones that fitted its own write bound, so the tree is clean when you start. What is left are values it confirmed wrong but may not write, because the true value needs more than an in-place edit of the value itself.

    Each item carries a value already verified against the source quoted beside it. Take it as given and make the code match it: do not spend web calls re-verifying it. Bound the edit to what the true value requires and nothing else. Files the list does not name are in scope when the true value requires them (call sites, types, tests), and nothing beyond that is. Amend the tests that carry the old value rather than opening a test-first cycle for the new one.

    Do NOT commit. A targeted fact-check pass runs behind you, verifies your work against the live sources, and commits it.
  "
)
```

Handle the implementer's exit state:

- **IMPLEMENTATION COMPLETE**: carry any `Unverified external value:` bullets it reports into the §2b prompt rather than into `$UNVERIFIED_FACTS`, which §2 has already consumed. Then go to §2b.
- **IMPLEMENTATION BLOCKED**: handle it exactly as §1a. Present the block to the developer (what blocks, what was tried, state of the tree) and ask how to proceed, and do NOT run the re-check on a blocked tree.

## 2b. Targeted re-check (fresh sub-agent)

Display:
```
--- Fact Check: Re-check ---
Verifying the applied corrections against live sources...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-fact-checker",
  model="opus",
  description="Re-check relayed facts",
  prompt="
    Plan file: $PLAN_PATH
    Baseline: $BASELINE_SHA

    ## Targeted re-check

    {$RELAY_FACTS, verbatim}

    Unverified external values reported by the implementer that applied them:
    {its `Unverified external value:` bullets, or "none"}
  "
)
```

Handle the result. There are two outcomes and only two:

- **FACTS CORRECTED**: the re-check verified the implementer's work and committed it. Note the commit and continue to §3.
- **ISSUES FOUND**: this **ends the run**. Present the issues to the developer, state that the relay implementer's work is still uncommitted in the tree and which files it touches, and go straight to the §5 summary. Do not ask how to proceed, and do not relay a second time.

That branch is the one place in this skill where an `ISSUES FOUND` is presented without asking the developer anything, so here is why. An `ISSUES FOUND` from the re-check means one specific thing, that the pass holds proof the value is still wrong, unlike §1b's mixed bag of issues a hardener could not fix. Committing over a proven-false value is the exact defect this route exists to remove, so a skip branch would reopen it one layer down with the developer's signature on it. And §3 and §4 both diff from `$BASELINE_SHA`, so an uncommitted relay diff is invisible to both: continuing would end the run reporting success over work nothing read.

## 3. Standards enforcement (fresh sub-agent)

Display:
```
--- Standards Enforcement ---
Checking all changes against project coding standards...
```

Get the full diff since baseline:
```bash
CHANGED_FILES=$(git diff $BASELINE_SHA..HEAD --name-only)
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-standards-enforcer",
  model="opus",
  description="Enforce standards compliance",
  prompt="
    These files were modified since baseline ($BASELINE_SHA):
    $CHANGED_FILES
  "
)
```

Handle the result:

- **STANDARDS COMPLIANT**: Continue.
- **STANDARDS ENFORCED**: Note the fixes applied, continue.
- **ISSUES FOUND**: Present the issues to the user and ask how to proceed.

## 4. Final review (fresh sub-agent)

Display:
```
--- Final Review ---
Reviewing implementation against the full plan...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-final-reviewer",
  model="opus",
  description="Final implementation review",
  prompt="
    Plan file: $PLAN_PATH
    Baseline: $BASELINE_SHA

    A fact-check pass ran before you and may have committed corrections to external values. Review its commit like any other.
  "
)
```

## 5. Summary

Display:

```
--- Implementation Complete ---

Plan: $PLAN_PATH

Steps:
  Step 1: [title]: [committed / committed with N fixes / issues: action taken]
  Step 2: [title]: [committed / committed with N fixes / issues: action taken]
  ...

Fact check: [no external facts / N facts verified / N corrections applied / N corrections relayed to an implementer / issues: action taken / not run]

Fact-check relay:
["None", or what the fact check relayed to a fresh implementer and how it ended: "verified and committed by the re-check", or "the re-check found the value still wrong and ended the run, leaving these files uncommitted and unverified in the working tree: ..."]

Standards enforcement: [COMPLIANT / N fixes applied / not run]

Commits: (list all commits from $BASELINE_SHA to HEAD with hash and message)

Hardener remarks:
[remarks reported by the hardener across steps, collected from each STEP COMMITTED WITH FIXES; or "None"]

Final review remarks:
[remarks from the final review agent, or "not run"]

Fact-check judgment items:
[currency notes, unverified facts, and corrections that require a choice, from the fact check and from the targeted re-check if one ran, naming which pass raised each; or "None"]
```

The three pass status lines each carry a state for a run that stopped short of them: the §1b "stop" branch jumps straight here, a fact-check `ISSUES FOUND` the developer answers with "stop" leaves §3 and §4 unrun, and a §2b `ISSUES FOUND` ends the run on its own with those same two passes unrun. The summary must not imply a pass ran when it did not. On that third path it must also say the working tree is dirty: it still carries the relay implementer's uncommitted edits, name the files they touch, and state that nothing has verified them. An uncommitted tree the run announces is reported state rather than hidden state, and the developer finishes it by hand.

## References

- `references/workflow.md`: upstream workflow guide, including failure paths and how to resume an interrupted run.
- `references/design-decisions.md`: upstream rationale for the isolated passes.
