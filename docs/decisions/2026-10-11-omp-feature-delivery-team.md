# omp feature-delivery agent team

## Issue

omp (18.8.9) can define task agents with their own tools, spawn policy, model
role, output schema, autoloaded skills, and advisor, and can load agents and
slash commands from extension package directories. This repository uses none
of it: `scripts/agent-harnesses.py` renders each `.codex/agents/*.toml`
specialist into `~/.omp/agent/agents/<name>.md` as a two-field stub (`name`,
`description`) that only points back at the TOML, so omp sees six domain
experts with no tool limits, model routing, or result contracts, and there is
no repeatable workflow that delivers a feature with them. This decision adds
an omp-only agent team and a `/deliver` command that runs a feature from plan
to pull request, with the human approving at fixed gates.

## Status

This is a proposal that is **awaiting review**.

## Assumptions and Constraints

- omp discovers agents and commands from `<extension-root>/agents/*.md` and
  `<extension-root>/commands/*.md` for every directory listed in the
  `extensions:` setting (`omp://task-agent-discovery.md`,
  `omp://slash-command-internals.md`). A directory with no entry module
  counts: a throwaway package holding only `package.json` and `commands/`
  had its command listed by RPC `get_available_commands` under
  `omp --mode rpc --no-session -e <dir>`, with or without an `index.ts`.
- omp's bundled agents (`omp agents unpack`) express frontmatter `output` in
  JSON Type Definition form (`properties`, `optionalProperties`, `elements`,
  `type`), list `model` as `@role` aliases, and use camelCase keys.
- `~/.omp/agent/agents/` is generator-owned: `GENERATED_ITEM_ROOTS` in
  `scripts/agent-harnesses.py` prunes any `*.md` there that `generate` did not
  produce, so hand-authored agents cannot live in it.
- Subagents run headless: the executor forces `tools.approvalMode: yolo` and
  supplies no UI, so a subagent cannot hold a human approval gate.
- Agent names are first-wins across discovery roots, and user agents outrank
  extension agents; a team name must not collide with an existing user or
  bundled agent (`reviewer`, `task`, …).
- `.gitignore` ignores `.omp/agent/*` with per-directory re-includes, and a
  global `packages/` rule ignores any `packages/` directory.
- A worktree of this repository is not the `~/.omp` omp reads, so pre-merge
  verification points omp at the worktree package explicitly.
- The default omp profile's `~/.omp/agent/config.yml` is the only config this
  decision targets. The `casper`, `subconscious`, and `baseten` profiles'
  `config.yml` files are renders (`just generate-omp-profiles`) of the main
  config merged with each profile's `overrides.yml`: maps merge, scalars and
  arrays replace, and the main config's `modelRoles` never carry over. A main
  `extensions:` array therefore reaches every profile, without the
  `delivery_*` roles, unless an `overrides.yml` replaces it.

## Argument

**Chosen: an omp-only extension package of declarative agents plus one
workflow command, with the main session as lead.** Agent frontmatter carries
every control the team needs — tools, `@role` models, output schemas,
autoloaded skills — without code, and the package is self-contained, so it
neither fights the generator's ownership of `~/.omp/agent/agents/` nor touches
the shared harness pipeline.

Sharing the team across harnesses through the canonical `.codex/agents` TOML
(**Rejected**) would either give omp the same featureless stubs it has today
or need an omp-only overlay on a Codex-format file; the omp features are the
point of the change.

The main session leads because only it can ask the human. A lead subagent
(**Rejected**) could not stop at either gate. Planning stays with the human in
the main session through the existing `brainstorm` and `writing-plans` skills,
because a plan is where judgment matters most and a headless planner cannot ask
questions.

A scripted eval `agent()`/`workpool()` driver and a TypeScript extension with
spawn-routing hooks are deferred, not chosen: the first trades steerability for
determinism the team does not yet need, and the second adds in-process code
with no current requirement for it.

## Architectural Decision

1. **Package.** The team is an omp extension package at
   `~/.omp/agent/teams/feature-delivery/`, registered in
   `~/.omp/agent/config.yml` as
   `extensions: [~/.omp/agent/teams/feature-delivery]`, and tracked through a
   `!.omp/agent/teams/` re-include in `.gitignore`. It contains `package.json`,
   `commands/deliver.md`, and one `agents/<name>.md` per member, and no
   `index.ts`. Each profile's `overrides.yml` sets `extensions: []`, so
   the rendered profile configs do not load the team; a profile opts in later
   by adding its own `extensions:` entry and `delivery_*` `modelRoles` to its
   `overrides.yml`.
2. **Lead.** `/deliver <feature description>` (`commands/deliver.md`, with
   `description` and `argument-hint` frontmatter, input via `$ARGUMENTS`)
   turns the main session into the lead. It loads existing skills by name and
   never inlines them. Every human gate is held by the lead; no team member
   holds one.
3. **Members.** Each member's model is a `@role` alias whose concrete selector
   lives in `modelRoles`, so models change without editing agent files:

   | Agent                  | Model role → default                        | Tools                                                      | Autoloaded skills         | Result fields                                                      |
   | ---------------------- | ------------------------------------------- | ---------------------------------------------------------- | ------------------------- | ------------------------------------------------------------------ |
   | `delivery-builder`     | `delivery_build` → `anthropic/claude-sonnet-5-5:high` | `read`, `grep`, `glob`, `find`, `edit`, `write`, `bash`, `lsp`, `ast_edit` | `test-driven-development` | `summary`, `files_changed`, `tests_added`, `open_questions`        |
   | `delivery-tester`      | `delivery_test` → `anthropic/claude-haiku-5-5:auto`  | `read`, `grep`, `glob`, `bash`                             | —                         | `commands_run`, `passed`, `failures` (with output excerpts)        |
   | `delivery-reviewer`    | `delivery_review` → `anthropic/claude-opus-5-5:xhigh` | `read`, `grep`, `glob`, `bash`                             | —                         | `verdict`, `findings` (`severity`, `path`, `line`, `issue`, `fix`) |

   `delivery-reviewer` loads no skill: `requesting-code-review` addresses the
   party asking for a review (it says to dispatch a reviewer and act on the
   findings), and the `code-reviewer.md` template it cites does not exist in
   this repository or in `~/.agents/skills`. The reviewer's own prompt states
   its criteria — correctness against the `PLAN.md` step, test adequacy,
   error handling, security-sensitive changes, and consistency with
   surrounding code — and maps them onto its result fields. Its `severity` is
   one of `blocker`, `major`, `minor`, or `nit`, and only `blocker` means the
   change must not ship as is. The bundled `security-reviewer` returns its own
   shape (`findings` with `severity` of `critical`, `high`, `medium`, `low`, or
   `informational`, and `locations`); the lead treats `critical` and `high` as
   blockers, and normalizes both reviewers' findings into one list of
   severity, path, line, issue, and suggested fix for the builder and for
   Gate 2. "Blocker findings" anywhere in this decision means that set.

   Result fields are enforced through each agent's `output` schema. Only the
   builder holds file-editing tools, and every member's prompt forbids
   commits, pushes, stashes, branch switches, and other ref writes. All three
   keep `bash` under forced `yolo`, so that is an instruction, not a sandbox;
   the lead enforces it. After every subagent run the lead dispatches —
   builder, tester, reviewer, and the bundled `security-reviewer`, whose
   bundled tool list has no `bash` but which is checked the same way — the
   lead compares `git rev-parse HEAD` and `git for-each-ref` — which covers
   `refs/stash` and the remote-tracking refs a push updates — against the
   Phase 0 baseline; any ref difference stops the run. The tester's prompt
   requires check-only invocations (no `--fix`, no snapshot updates). Around
   each tester and reviewer run the lead also snapshots the working tree —
   `git diff HEAD --binary | git hash-object --stdin` plus
   `git ls-files --others --exclude-standard`, taken immediately before the
   run so the builder's uncommitted changes are part of the baseline — and
   compares it afterwards. Gitignored output is therefore never flagged. A
   tree difference does not stop the run automatically: the lead lists the
   changed paths and the human chooses to revert them, keep them, or end the
   run. The `delivery-` prefix keeps names clear of user and bundled agents.
4. **Phases.**

   | # | Phase     | Actor                                                | Exit condition                                                          |
   | - | --------- | ---------------------------------------------------- | ----------------------------------------------------------------------- |
   | 0 | Preflight | lead                                                 | not on the default branch (or the human confirms); base SHA and `git for-each-ref` baseline recorded |
   | 1 | Plan      | lead with human: `brainstorm` → `writing-plans`      | **Gate 1:** human approves `PLAN.md`                                     |
   | 2 | Build     | `delivery-builder`, one `PLAN.md` step per message   | step result has no open questions; step ticked in `PLAN.md`             |
   | 3 | Check     | `delivery-tester`, after every step                  | `passed: true`                                                          |
   | 4 | Review    | lead loads `requesting-code-review`, then dispatches `delivery-reviewer` and bundled `security-reviewer` in parallel | no blocker findings, or two review rounds spent                         |
   | 5 | Ship      | lead: `git-commit` (local commits only) → **Gate 2** → `pr-create` | **Gate 2:** human approves the local commits and any remaining findings; only then does `pr-create` push |

   One builder instance serves every step and receives follow-ups through
   `write agent://<id>`, keeping its context. The lead passes step numbers,
   prior results, and failure excerpts; members read `PLAN.md` and the
   repository themselves. Review covers `git diff <base>` plus the untracked
   files `git status --porcelain` lists. The lead updates `PLAN.md`'s
   `## Status` after each step so an interrupted run can resume from it.
   `PLAN.md` is the one tracked change made before Phase 5: the lead commits it
   at Gate 1 and after each `## Status` update, in commits that touch only
   `PLAN.md`, and re-records the `HEAD` and `git for-each-ref` baseline after
   each such commit. Code changes stay uncommitted until Phase 5. In Phase 5
   the lead runs `git-commit` to group the changes into local commits, then
   holds Gate 2 with those commits and any remaining findings in front of the
   human. Nothing is pushed before Gate 2, `PLAN.md` commits included; on
   approval `pr-create` pushes the branch, and on rejection the commits stay
   local for the human to amend, reset, or discard.
5. **Failure policy.** Every escalation and stop goes to the human in the
   main session. Open questions from the builder pause the run until the
   human answers, and the answer goes to the same agent. A step that cannot
   be done as planned stops the run for a `PLAN.md` revision. A failing check
   returns to the builder at most twice per step; a third failure escalates to
   the human, who fixes the plan, steers the builder, or ends the run. Blocker
   findings return to the builder for at most two review rounds; after each
   round's fixes `delivery-tester` reruns, under the same two-retry limit,
   before the next review round. Blockers that remain after the second round
   do not stop the run: they are presented at Gate 2 for the human to accept,
   fix, or abandon. An agent that fails, aborts, or returns schema-invalid
   output gets one retry on the same agent; a second failure stops the run and
   reports the agent's `agent://` and `history://` links.
6. **Out of scope.** No commits before Phase 5 other than the lead's
   `PLAN.md` commits, and no push before Gate 2 (clause 4), no `TODO.md`
   cache, no parallel
   build steps or isolated worktrees, no automatic merge, no advisor or
   `WATCHDOG.yml`, no extension hooks or custom tools.
7. **Generator untouched.** `scripts/agent-harnesses.py` and the harness
   capability matrix are unchanged. The package is a local omp-only addition,
   not a harness divergence: the matrix's `divergent` state is reserved for
   permanent upstream differences.

A representative member definition, pinning the frontmatter contract:

```yaml
---
name: delivery-tester
description: Runs a repository's tests and linters for one delivery step and reports pass/fail.
model:
  - "@delivery_test"
tools:
  - read
  - grep
  - glob
  - bash
output:
  properties:
    commands_run:
      elements: { type: string }
    passed:
      type: boolean
    failures:
      elements:
        properties:
          command: { type: string }
          excerpt: { type: string }
---
```

## Consequences

- Verification before merge: load the worktree package with
  `omp -e <worktree package>` and confirm `/deliver` appears in RPC
  `get_available_commands`; spawn
  each member headlessly on a scratch repository and confirm its resolved
  model role, schema-valid result, and (for tester and reviewer) absence of
  file-editing tools; then run `/deliver` end to end on a scratch repository
  for a one-function feature, including one forced test failure. `hk check`
  (including its `omp-profiles` step), `just generate-omp-profiles` with a
  clean diff afterwards, and `scripts/agent-harnesses.py generate --check`
  must stay green.
- After merge, one `/deliver` dry run from the real `$HOME` checkout confirms
  the registered `extensions:` path and `modelRoles` entries.
- Named profiles do not get the team: their rendered `config.yml` carries
  `extensions: []` from `overrides.yml` until a profile opts in there.

## Positions

- **Shared roles in `.codex/agents` plus an omp overlay.** Rejected: keeps
  cross-harness parity the user did not ask for, at the cost of an overlay on
  a Codex-format source.
- **Shared roles only.** Rejected: omp keeps today's stubs, losing the
  controls that motivate the change.
- **New omp source directory rendered by `agent-harnesses.py`.** Rejected in
  favor of a self-contained package that leaves the generator alone.
- **Hand-authored files in `~/.omp/agent/agents/`.** Rejected: the generator
  prunes them, and exempting them mixes hand-written and generated files.
- **A planner subagent drafts the plan for approval.** Rejected: it cannot ask
  the clarifying questions a plan depends on.
- **Autonomous run to a draft PR.** Rejected: no gate before code is written.
- **A `packages/` directory.** Rejected: the global `packages/` ignore rule
  would hide it from git.

## References

- `omp://task-agent-discovery.md` — agent frontmatter, discovery precedence,
  model and output-schema precedence.
- `omp://tools/task.md` — batch dispatch, agent lifecycle, `agent://` and
  `history://`.
- `omp://slash-command-internals.md` — command discovery and `$ARGUMENTS`.
- `omp://extension-loading.md` — extension package directories and
  `extensions:`.
- [2026-09-07-adopt-conventional-docs](./2026-09-07-adopt-conventional-docs.md)
  — `PLAN.md` lifecycle used by the Plan phase.
