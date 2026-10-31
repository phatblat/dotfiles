# Workflow

Part of [spec-driven-dev](https://github.com/mkrtchian/spec-driven-dev/blob/main/README.md).

## 1. Discuss and plan

Start a conversation with Claude Code. If you have requirements from a product discovery (user stories, acceptance criteria, technical constraints), give them as context:

```
/write-plan path/to/requirements.md
```

Or just launch it with an idea:

```
/write-plan Add a dark mode toggle to the user settings page
```

Commands are namespaced: if another plugin also provides `/write-plan`, use `/spec-driven-dev:write-plan`.

The agent will:

1. **Discuss**: Explore the codebase, ask you clarifying questions about requirements and technical approach, until you both have a shared understanding.
2. **Draft**: Write a detailed implementation plan to `plans/YYYY-MM-DD_feature-name.md`.
3. **Review the plan** (fresh agent): Check for gaps, wrong assumptions, integration risks. Auto-corrects the plan.
4. **Check standards** (fresh agent): Verify the plan respects project coding and testing conventions. Auto-corrects.
5. **Run due diligence** (fresh agent): Web-verify the external facts the plan cites (versions, API contracts, action names) against live sources, and surface the risks and decisions you would implicitly approve by executing the plan. Fixes factual errors, flags judgment calls, including the facts the plan defers to implementation instead of citing. Records what it settled and what it left open in a `## Due diligence record` section of the plan, so the implementation phase can read it.
6. **Break into steps** (fresh agent): Split the plan into the fewest ordered implementation steps that fit within an agent's context budget.

The command ends here. You review the plan and make necessary changes (manually or by asking the agent to make the adjustments), and the command proposes committing the plan so it exists in git before you implement it. The plan you commit now carries the due diligence record, so what plan-time verification concluded is still readable when the code gets written. The command also repeats what needs your judgment, including any `<!-- REVIEW: ... -->` marker a review pass left in the plan for a decision it could not make. Nothing checks that you resolved them, so resolve them before you implement: the breakdown cuts steps over them, and the implementer reads what it is handed.

## 2. Implement

Once the plan looks good, commit or stash anything unrelated in your working tree (the passes read the whole diff, and the hardener commits what it finds uncommitted), check out the branch the work should land on, clear context, and run:

```
/implement-plan plans/YYYY-MM-DD_feature-name.md
```

The orchestrator executes each step from the plan:

**For each step:**

- **Implementer** (fresh agent): For business logic, writes all tests first (red), then implements to pass (green). For glue code, implements directly. Runs tests, lint, typecheck. Does not commit.
- **Step hardener** (fresh agent): Catches drift from the plan and emergent issues (broken imports, type mismatches, edge cases), fixes them, and commits the step. Flags trade-offs it can't resolve.

**After all steps:**

- **Fact check** (fresh agent): Verifies the external facts the implementation put into the code (versions, API fields, endpoints, published values) against live sources, reading the plan's `## Due diligence record` to know where to look first. Fixes facts that are wrong, flags currency notes and facts it could not verify, and commits. Gated: a diff with no third-party surface costs a single diff read and no web call. Three outcomes do not stop the run at this pass: a value that is valid but not the latest, a value it could not verify, and a value confirmed wrong whose correction exceeds what this pass may write. The first two land in the summary's judgment items. The third outcome splits on whether the artifacts settle it. When the plan, the code and the source hold a single right answer, the orchestrator hands the finding to a fresh implementer that applies it without committing, and a targeted fact-check pass re-verifies the corrected value against its source and commits it, so the run continues with the value fixed rather than flagged. When the correction takes a choice instead, it goes to the summary's judgment items with the true value and its source beside it, and the code carries the wrong value until you decide, so read that block. One relay per run: if the re-check finds the value still wrong, it commits nothing and the run ends there rather than trying again.
- **Standards enforcement** (fresh agent): Checks the full diff against project coding standards. Fixes violations directly, verifies (tests, lint, typecheck), and commits.
- **Final review** (fresh agent): Reads the full plan and full diff. Fixes obvious issues directly (typos, wrong imports, dead code, convention violations) and commits them. Flags trade-offs and architectural choices as remarks for you to decide. When the diff touches a trust boundary (an auth check, a secret, a dependency, or outside data reaching a query, a command or a deserializer), it also checks security: it fixes the patterns that have a canonical correction and flags the rest. A secret in the diff is flagged rather than removed, since removing it in a later commit would leave it in your local history. Rewrite history before pushing, and rotate the secret.

## 3. Review and adjust

Check the result. The plan is still there as the reference: you can point to specific sections and ask for adjustments.

### When things go wrong

The orchestrator stops when an agent can't resolve an issue on its own, and asks you how to proceed in every case but one:

- **Implementer reports it is blocked** (verification cannot be made to pass, or the step's approach is invalid): the orchestrator presents the block and asks how to proceed, without hardening the step.
- **Hardener finds issues it can't fix** (architectural trade-offs, ambiguous requirements): you choose to fix, skip, or stop. Fix sends a fresh implementer at the findings, then hardens again. If the same step comes back a second time, the orchestrator says so and names which findings the new report repeats, since nothing else tells you the step is not converging. Skip commits the step as it stands, issues included and verification unproven, and moves on. Stop goes straight to the summary.
- **Fact checker returns issues it can't repair** (a correction against a live source breaks verification and can't be cleanly reverted): the orchestrator presents the issues and asks how to proceed. A fact it simply could not verify is not this case: it rides along as a judgment item and the run continues.
- **The relay fails**, in either of two ways, which are not handled alike. A relay implementer that reports itself blocked is presented to you and asked about, like any other block, and the re-check never runs. A re-check that finds the relayed value still wrong ends the run instead of asking: nothing is committed, the implementer's corrections stay uncommitted in the working tree, the standards and final review passes never run, and you finish by hand. There is nothing to ask there, since committing a value a pass proved false is what the relay exists to prevent, and continuing without committing would hide a multi-file change from the two passes that read the diff since the run started.
- **Standards enforcer finds unresolvable violations**: same, you decide.

In all cases, the plan is still the reference. You can adjust it, ask the agent to retry a step, or finish manually.

There is no resume. Starting `/implement-plan` again begins at the first step with no knowledge of what already landed, and nothing tells an implementer what to do with a step whose code is already there. Finish by hand, or reset the branch to the pre-run state and replay the plan whole. Two paths leave a dirty tree behind for you to finish: a step whose implementer reported itself blocked, whose report names what it changed and left uncommitted, and a relay whose re-check ended the run, where the summary names the files carrying the uncommitted corrections and states that nothing has verified them. The post-step passes also read only the diff since the command started, so anything an earlier run committed falls outside them.

## Small changes

For a change that doesn't need a reviewed plan, run the command in the session where you discussed it, on the branch the work should land on:

```
/small-change Add a --dry-run flag to the export command
```

1. **Intent**: The main session writes three to five lines of intent (the need, what counts as done, the files it expects to touch). It shows them and goes on without asking you to approve them.
2. **Triage**: If your project states which changes need a plan (see below), the command checks the intent against that rule. When the rule says the change needs a plan, the command says which rule, recommends `/write-plan`, and asks whether to go on anyway.
3. **Implement**: The main session writes the code, test-first for business logic as the implementer does, and runs your tests, lint and typecheck. It commits the change with the intent in the commit body.
4. **Fact check** (fresh agent): Runs the same pass as in `/implement-plan`, reading the intent instead of a plan.
5. **Standards enforcement** (fresh agent): Runs the same pass, on the files changed since the command started.
6. **Final review** (fresh agent): Checks the diff against the intent, both what the diff misses and what it changes beyond the intent. Fixes what has one answer and flags the rest, and runs the conditional security check described in section 2.

The summary lists every commit since the command started, the change first and each pass's fixes after it, so the fixes of a pass you disagree with can be reverted on their own. Squash them if you want a single commit.

The plugin sets no size threshold. If a `CLAUDE.md` at the root or in a directory the change touches says which changes need a plan (for example "any schema change goes through /write-plan"), the command applies that rule before writing code, and the final review flags a diff that, by that rule, needed a plan. Without such a rule, the command never stops at triage.

### When things go wrong

- **A file the change will touch has uncommitted edits**: the command stops and asks you to commit or stash them, because its commit stages files by name and would take your edits with it. It never stashes for you. Other uncommitted files don't stop it unless the change ends up touching one, in which case it stops before committing and asks, for the same reason. The summary names those other uncommitted files.
- **Tests, lint or typecheck won't pass**: nothing is committed and no review pass runs. The command tells you what fails and which files carry the uncommitted change. There is no resume: finish and commit by hand, or discard the change before running `/small-change` again.
- **The fact check or the standards enforcer returns issues it can't resolve**: you choose how to proceed, as in `/implement-plan`. If you stop, the summary says which passes did not run.
- **The fact check confirms a value wrong, with one right answer, but can't correct it in place**: `/small-change` has no relay. The value stays in the code, and the summary shows it first, with the true value and its source. A correction that needs a decision goes with the other judgment items.

## Why isolated context?

See [design-decisions.md](design-decisions.md) for the rationale behind isolated contexts, sequential execution, external fact checking, and plans in git, with the sources that back each choice.
