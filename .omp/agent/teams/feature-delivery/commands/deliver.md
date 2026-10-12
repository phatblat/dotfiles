---
description: Deliver a feature with the delivery team — plan with you, build, test and review with subagents, ship after your approval
argument-hint: <feature description | accepted decision id>
---

# /deliver

You are the lead of a feature-delivery run. Request: $ARGUMENTS

You hold every human gate. The team — `delivery-builder`,
`delivery-tester`, `delivery-reviewer`, and the bundled `security-reviewer`
— runs headless through the `task` tool and never talks to the human.
Load skills by reading `skill://<name>`; never work from memory of them.
Wherever this command says "ask", use the `ask` tool with exactly the
options given.

Every `task` call passes `context` with: the repository root, the base
commit `BASE`, that `PLAN.md` is at the repository root, and the rule that
no member may commit, push, stash, switch branches, or otherwise write refs
or the index.

## Checks

- **Ref baseline.** `git rev-parse HEAD` plus
  `git for-each-ref --format='%(objectname) %(refname)'`, recorded verbatim.
  Re-record it after every commit you make.
- **Ref check** — after every member run (builder, tester, reviewer,
  security-reviewer): recompute both and compare with the baseline. Any
  difference stops the run: report the difference, the member, and its
  `agent://<id>` and `history://<id>` links to the human.
- **Tree snapshot** — immediately before every tester, reviewer, and
  security-reviewer run, record `git diff HEAD --binary | git hash-object --stdin`,
  `git ls-files --others --exclude-standard`, `git status --porcelain`, and
  `SNAP=$(git stash create)` (empty output means use `SNAP=HEAD`;
  `git stash create` writes no ref).
- **Tree check** — after those runs, recompute the hash and the untracked
  list. If either differs, list the changed paths (difference between the
  two `git status --porcelain` outputs) and ask: "Revert these changes" /
  "Keep them" / "End the run". Revert: `git restore --source=$SNAP --worktree -- <changed tracked paths>`
  and delete untracked paths absent from the pre-run list; report any
  pre-existing untracked file that changed, since it cannot be restored.
- **Member failure** — a member that fails, aborts, or returns
  schema-invalid output gets one retry on the same agent (the builder via
  `write agent://<builder id>`, others by re-dispatching) with the error
  text; a second failure stops the run and reports its `agent://` and
  `history://` links.

## PLAN.md commits

Commit `PLAN.md` alone with `git commit -m "<subject>" -- PLAN.md`. Run
`git add PLAN.md` first for the first commit (`PLAN.md` is untracked until
then and the pathspec would not match) and `git rm PLAN.md` first for the
removal. Subjects: when the run implements a
decision id and the repository has `docs/decisions/`, use
`plan: start <id>`, `docs: update plan status`, and `plan: done <id>`;
otherwise `docs: add plan`, `docs: update plan status`, and
`docs: remove plan`. Match the repository's documented capitalization after
the colon. Never push before Gate 2.

## Phase 0 — Preflight

1. Empty request: ask for a feature description, then continue with it.
2. `git rev-parse --show-toplevel` fails: say /deliver needs a git
   repository and stop.
3. Default branch: `git symbolic-ref --short refs/remotes/origin/HEAD`
   without its `origin/` prefix; if that fails, `main` when it exists, else
   `master`. On the default branch, ask: "Create branch feat/<slug>" (slug:
   kebab-case of the request, at most 40 characters) / "Continue on
   <default branch>" / "Stop". Create with `git switch -c`.
4. `git status --porcelain` non-empty: ask "Include these existing changes
   in the delivery" / "Stop".
5. `PLAN.md` exists at the repository root: read it and ask "Resume this
   plan" / "Stop". Resume skips Phase 1 and continues Phase 2 at the first
   task with unchecked boxes.
6. Record `BASE=$(git rev-parse HEAD)` and the ref baseline.

## Phase 1 — Plan (Gate 1)

If the request matches `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+$` and
`docs/decisions/<request>.md` exists, read it: unless its `## Status` says
**accepted**, tell the human to accept it first and stop; otherwise skip to
step 3 with that decision.

1. Read `skill://brainstorm` and follow it for the request with the human.
2. Act on its classification:
   - **Probe:** finish the probe, report it, and stop; nothing is built.
   - **Decision:** follow brainstorm through writing, committing, and
     self-reviewing the proposed Decision, then stop: tell the human to
     review and accept it, then run `/deliver <decision id>`. No member
     has run, so this commit precedes every check.
   - **Direct:** once the human approves the short design, continue.
3. Write `PLAN.md` at the repository root. For a decision id, read
   `skill://writing-plans` and follow it for that decision. For the Direct
   path, follow writing-plans' format with the header line
   `**Decision:** none — Direct path`; in /deliver this replaces
   writing-plans' rule that a plan needs an accepted decision. Either way:
   omit every per-task commit step and the final "Retire the Plan" task
   (all commits happen in Phase 5, which removes `PLAN.md`), and end the
   file with `## Status` reading `Not started.`
4. **Gate 1:** show the plan path and its task headings, then ask
   "Approve plan" / "Revise plan" / "Stop". Revise: apply the human's
   changes and ask again.
5. On approval commit `PLAN.md` (start subject) and re-record the ref
   baseline.

## Phases 2–3 — Build and check, one task at a time

The unit of work is one `### Task N` of `PLAN.md`, in order. For each:

1. **Build.** First task of the run: dispatch `agent: "delivery-builder"`,
   `name: "DeliveryBuilder"`, a `task` naming the task number and heading,
   and a `solutionSpace` saying the task is fixed by `PLAN.md` and only
   implementation detail is open. Use the agent id the call returns for
   every later task and fix: `write agent://<builder id>` with the message,
   then wait for its result; if none is delivered, read
   `agent://<builder id>` for its latest result. Ref check.
2. `open_questions` non-empty: ask the human each question, send the
   answers to the builder, and repeat from the ref check. If the task
   cannot be done as written, stop and ask the human to revise `PLAN.md`.
3. **Check.** Tree snapshot; dispatch `agent: "delivery-tester"` with a
   task naming the `PLAN.md` task just built and `solutionSpace`
   "no fix; run the checks and report". Ref check and tree check.
4. `passed` false: send the `failures` to the builder, ref check, and
   repeat step 3. When the third check of this task fails (two fix
   attempts spent), ask "Revise PLAN.md" / "Steer the builder" (send the
   human's text to the builder, then repeat step 3) / "End the run".
5. `passed` true: only now tick the task's checkboxes in `PLAN.md` (a
   task that never passed its check must stay unticked so resume does not
   skip it), set `## Status` to "Task N built and checked" plus anything
   notable, commit `PLAN.md` (status subject), and re-record the ref
   baseline.

## Phase 4 — Review

1. Read `skill://requesting-code-review`.
2. Tree snapshot. List `CHANGED`: `git diff --name-only BASE` plus
   `git ls-files --others --exclude-standard`. In one `task` call dispatch
   `agent: "delivery-reviewer"` (task: base `BASE`, `PLAN.md`, every task
   heading) and `agent: "security-reviewer"` (task: review the files in
   `CHANGED`, listed in the task, for vulnerabilities; it has no `bash`, so
   it reads the files directly and cannot run git). Ref check and tree
   check.
3. Normalize every finding to severity, path, line, issue, fix:
   `delivery-reviewer` entries as returned. `security-reviewer` returns
   `findings` (absent or empty means none) with `severity`, `title`,
   `summary`, `locations` (each `path` and `start_line`), and optional
   `remediation`: map severity `critical`/`high` → `blocker`, `medium` →
   `major`, `low` → `minor`, `informational` → `nit`; path and line from the
   first `locations` entry's `path` and `start_line`; issue from `title`
   and `summary`; fix from `remediation`, else "see security finding". A
   missing field or unrecognized severity never drops a finding: use path
   `unknown`, line 0, severity `major`, and the raw finding text as the
   issue. Blocker findings are exactly the `blocker` entries.
4. No blockers: go to Phase 5. Otherwise send the blockers to the builder
   (ref check), rerun the Phase 3 check under the same two-retry limit,
   and run a second review round from step 2. Blockers left after the
   second round go to Gate 2.

## Phase 5 — Ship (Gate 2)

1. Read `skill://git-commit` and follow it to group the uncommitted changes
   into local commits. Do not push.
2. **Gate 2:** show `git log --oneline BASE..HEAD`,
   `git diff --stat BASE..HEAD`, and every remaining finding, blockers
   first. Ask "Approve — remove PLAN.md and open the PR" / "Request
   changes" / "Stop here (keep local commits)".
   - **Request changes:** send the human's change to the builder, then run
     one Phase 3 check with the human's requested change as the tester's
     check context in place of a `PLAN.md` task, and one Phase 4 review
     round; repeat step 1 (new commits on top), and ask Gate 2 again.
   - **Stop:** report the local commits and end; nothing is pushed.
   - **Approve:** commit the removal of `PLAN.md` (done subject), then
     read `skill://pr-create` and follow it. That is the run's first push.
