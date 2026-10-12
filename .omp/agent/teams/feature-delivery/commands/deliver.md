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

- **Ref baseline.** `git rev-parse HEAD`,
  `git for-each-ref --format='%(objectname) %(refname)'`, and
  `git write-tree` (the index's tree id, so staged changes show up; it
  writes no ref and leaves the index as is), recorded verbatim. Re-record
  it after every commit you make.
- **Ref check** — after every member run (builder, tester, reviewer,
  security-reviewer): recompute all three and compare with the baseline.
  Any difference stops the run: report the difference, the member, and its
  `agent://<id>` and `history://<id>` links to the human.
- **Tree snapshot** — immediately before every tester, reviewer, and
  security-reviewer run, record `git diff HEAD --binary | git hash-object --stdin`
  (tracked files), `git ls-files -z --others --exclude-standard | while IFS= read -r -d '' f; do if [ -f "$f" ] || [ -L "$f" ]; then git hash-object -- "$f"; fi; done | git hash-object --stdin`
  (untracked file contents; the loop skips non-file entries such as a
  nested repository's `dir/` and is safe on an empty list, unlike
  `xargs`; never `git add -N`, which writes the index),
  `git ls-files --others --exclude-standard`, `git status --porcelain`, and
  `SNAP=$(git stash create)` (empty output means use `SNAP=HEAD`;
  `git stash create` writes no ref).
- **Tree check** — after those runs, recompute both hashes and the
  untracked list. If any differs, list the changed paths (difference
  between the two `git status --porcelain` outputs, plus untracked files
  whose content hash changed) and ask: "Revert these changes" /
  "Keep them" / "End the run". Revert: `git restore --source=$SNAP --worktree -- <changed tracked paths>`
  and delete untracked paths absent from the pre-run list; report any
  pre-existing untracked file that changed, since it cannot be restored.
  After a tester run, a difference confined to untracked paths the check
  commands plausibly produced (caches, build output, coverage reports) is
  not a violation: name the paths in your report and keep them without
  asking; any tracked-file change or other untracked change is asked about
  as above.
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
   repository and stop. Otherwise `cd` to its output and run every command
   from there (`PLAN.md`, `':!PLAN.md'`, `git commit -- PLAN.md` and the
   changed-file lists are all relative to it), and pass it as the
   repository root in every `task` context.
3. `git status --porcelain` non-empty, ignoring an untracked `PLAN.md`
   (step 4 handles it): ask "Include these existing changes in the
   delivery" / "Stop".
4. `PLAN.md` exists at the repository root: unless it has a `**Base:**` or
   `**Decision:**` header line it is not a /deliver plan; say so, tell the
   human to move or remove it, and stop. Otherwise read it and ask "Resume
   this plan" / "Stop" (to start over, the human removes `PLAN.md` first
   and reruns). Resume skips the branch step (5), staying on the current
   branch, and skips Phase 1 except as follows: if
   `git ls-files --error-unmatch PLAN.md` fails (never committed, so never
   approved), go to Phase 1 step 4 (Gate 1) and then its step 5 (the start
   commit). Otherwise continue Phase 2 at the first task with unchecked
   boxes, or go straight to Phase 4 when every task is ticked. A resumed
   run has no builder agent id: dispatch a fresh `DeliveryBuilder` when
   one is first needed and tell it earlier uncommitted work may already be
   in the tree.
5. Default branch: `git symbolic-ref --short refs/remotes/origin/HEAD`
   without its `origin/` prefix; if that fails, `main` when it exists, else
   `master`. On the default branch, ask: "Create branch feat/<slug>" (slug:
   kebab-case of the request, at most 40 characters) / "Continue on
   <default branch>" / "Stop". Create with `git switch -c`. This runs after
   every other stop-capable step so a "Stop" never leaves an empty branch.
6. Record `BASE`. Fresh run: `git rev-parse HEAD`. Resume: the sha in
   `PLAN.md`'s `**Base:**` header when `git merge-base --is-ancestor <sha> HEAD`
   succeeds; otherwise (no header, or rewritten history)
   `git merge-base HEAD <default branch>`, the default branch found as in
   step 5 without asking. Then record the ref baseline.

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
   add the header line `**Base:** <BASE sha>` (a resumed run reads it
   back), omit every per-task commit step and the final "Retire the Plan"
   task (all commits happen in Phase 5, which removes `PLAN.md`), and end
   the file with `## Status` reading `Not started.`
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
   repeat step 3. When the third check fails (two fix attempts spent), ask
   "Revise PLAN.md" / "Steer the builder" (send the human's text to the
   builder, then repeat step 3) / "End the run". When the check has no
   single `PLAN.md` task (a review fix loop or Request changes), omit
   "Revise PLAN.md" and ask only "Steer the builder" / "End the run".
5. `passed` true: for a `### Task N` check, only now tick the task's
   checkboxes in `PLAN.md` (a task that never passed its check must stay
   unticked so resume does not skip it) and set `## Status` to "Task N
   built and checked" plus anything notable. When the check has no single
   task (a review fix loop or Request changes), tick nothing and set
   `## Status` to what was checked, for example "review fixes applied and
   checked". Commit `PLAN.md` (status subject) and re-record the ref
   baseline.

## Phase 4 — Review

1. Read `skill://requesting-code-review`.
2. Tree snapshot. List `CHANGED`: `git diff --name-only BASE -- ':!PLAN.md'`
   plus `git ls-files --others --exclude-standard` without `PLAN.md`
   (`PLAN.md` is process scaffolding, not part of the change). In one
   `task` call dispatch `agent: "delivery-reviewer"` (task: base `BASE`,
   `PLAN.md`, every task heading, and that the diff to review is
   `git diff BASE -- ':!PLAN.md'`, `PLAN.md` being scaffolding to read for
   requirements only) and `agent: "security-reviewer"` (task: review the
   files in `CHANGED`, listed in the task, for vulnerabilities; it has no
   `bash`, so it reads the files directly and cannot run git). Ref check
   and tree check.
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
   (ref check), rerun the Phase 3 check with the blocker findings as the
   tester's check context in place of a `PLAN.md` task, under the same
   two-retry limit and the no-single-task menu, and run a second review
   round from step 2. Blockers left after the second round go to Gate 2.

## Phase 5 — Ship (Gate 2)

1. Read `skill://git-commit` and follow it to group the uncommitted changes
   into local commits. Do not push.
2. **Gate 2:** show `git log --oneline BASE..HEAD`,
   `git diff --stat BASE..HEAD -- ':!PLAN.md'`, and every remaining finding, blockers
   first. Ask "Approve — remove PLAN.md and open the PR" / "Request
   changes" / "Stop here (keep local commits)".
   - **Request changes:** send the human's change to the builder, then run
     one Phase 3 check with the human's requested change as the tester's
     check context in place of a `PLAN.md` task, and one Phase 4 review
     round; repeat step 1 (new commits on top), and ask Gate 2 again.
   - **Stop:** report the local commits and end; nothing is pushed.
   - **Approve:** commit the removal of `PLAN.md` (done subject), then
     read `skill://pr-create` and follow it. That is the run's first push.
