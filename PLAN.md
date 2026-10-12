# Plan: 2026-10-11-omp-feature-delivery-team

Decision: [docs/decisions/2026-10-11-omp-feature-delivery-team.md](docs/decisions/2026-10-11-omp-feature-delivery-team.md)

## Steps

- [x] 1. Start the plan
- [x] 2. Add the package skeleton and the three agents
- [x] 3. Add the /deliver command
- [x] 4. Register the package in the default profile only
- [ ] 5. Verify, then retire the plan and open the PR

### Approach

#### 1. Start the plan

1. `cd ~/.worktrees/dotfiles/feat/omp-feature-delivery-team`; confirm
   `git branch --show-current` prints `feat/omp-feature-delivery-team` and
   `git status --porcelain` is empty.
2. Create `PLAN.md` at the worktree root, in this order: (a) the head below;
   (b) a `## Steps` section with one checklist line per Approach step —
   `- [ ] 1. Start the plan`, `- [ ] 2. Add the package skeleton and the three agents`,
   `- [ ] 3. Add the /deliver command`, `- [ ] 4. Register the package in the default profile only`,
   `- [ ] 5. Verify, then retire the plan and open the PR` — followed by this
   plan file's `## Approach`, `## Critical files & anchors`, `## Verification`,
   and `## Assumptions & contingencies` sections copied verbatim, each heading
   demoted one level (`##` → `###`, `###` → `####`); (c) the Status section
   below.

   ```markdown
   # Plan: 2026-10-11-omp-feature-delivery-team

   Decision: [docs/decisions/2026-10-11-omp-feature-delivery-team.md](docs/decisions/2026-10-11-omp-feature-delivery-team.md)
   ```

   ```markdown
   ## Status

   Not started.
   ```

3. Commit it alone:
   `git add PLAN.md && git commit -m "plan: start 2026-10-11-omp-feature-delivery-team" -m "Co-Authored-By: oh-my-pi <omp@can.ac>" -- PLAN.md`
   (repo rule: `plan:` event commits touch exactly one artifact).
4. At each later commit checkpoint, tick the finished items in `PLAN.md`, set
   `## Status` to one sentence saying where work stands, and commit `PLAN.md`
   alone as `docs: update plan status`.

#### 2. Add the package skeleton and the three agents

1. In `.gitignore`, insert the line `!.omp/agent/teams/` between
   `!.omp/agent/skills/` and `!.omp/agent/themes/` (that is where
   `scripts/sort-gitignore` places it: negation keys sort as `<path>~`, and
   `skills` < `teams` < `themes`). This mirrors how `!.omp/agent/agents/` and
   `!.omp/agent/commands/` re-include their trees; the existing
   `!.omp/agent/*/**/*.md`, `*.json`, and `!.omp/agent/*/**/` rules then track
   the package's files.
2. Create `.omp/agent/teams/feature-delivery/package.json` (no `index.ts`; a
   package directory without an entry module still contributes its `agents/`
   and `commands/` — verified for commands with
   `omp --mode rpc --no-session -e <dir>`):

   ```json
   {
     "name": "feature-delivery",
     "version": "0.0.0",
     "private": true,
     "description": "omp agent team and /deliver workflow that take a feature from an approved PLAN.md to a pull request.",
     "license": "MIT"
   }
   ```

3. Create `.omp/agent/teams/feature-delivery/agents/delivery-builder.md`:

   ```markdown
   ---
   name: delivery-builder
   description: Implements one PLAN.md task at a time, test first, leaving every change uncommitted for the delivery lead.
   model:
     - "@delivery_build"
   tools:
     - read
     - grep
     - glob
     - find
     - edit
     - write
     - bash
     - lsp
     - ast_edit
   autoloadSkills:
     - test-driven-development
   output:
     properties:
       summary:
         type: string
       files_changed:
         elements: { type: string }
       tests_added:
         elements: { type: string }
       open_questions:
         elements: { type: string }
   ---

   You are the builder on a feature-delivery team. The lead (the main session)
   sends you one `PLAN.md` task at a time, plus prior results and any test
   failures or review findings to fix. You never talk to the human; the lead
   does.

   For each message:

   1. Read `PLAN.md` at the repository root and the task you were given. Read
      the code you will change before changing it.
   2. Implement only that task, test first: write or update the failing test,
      watch it fail, make it pass. Run the tests relevant to the task with the
      repository's developer test command (from its README, AGENTS.md, or build
      files).
   3. When the lead sends test failures or review findings, fix exactly those,
      then rerun the relevant tests.
   4. If the task is ambiguous, contradicts the code, or cannot be done as
      written, do not guess: stop and put the question in `open_questions`.

   Hard rules:

   - Never run git commands that write refs or the index: no `git commit`,
     `push`, `stash`, `switch`, `checkout` of a branch, `reset`, `rebase`,
     `merge`, `tag`, or `add`. Leave every change uncommitted in the working
     tree.
   - Never edit `PLAN.md`; the lead owns it.
   - Stay inside the task: no unrelated refactors, renames, or formatting
     sweeps.

   Return `summary` (what you did for this message), `files_changed`
   (repository-relative paths you created, modified, or deleted),
   `tests_added` (test names or paths you added or changed), and
   `open_questions` (empty when none).
   ```

4. Create `.omp/agent/teams/feature-delivery/agents/delivery-tester.md`:

   ```markdown
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

   You are the tester on a feature-delivery team. After each build step the
   lead asks you to check the repository. You never talk to the human.

   1. Find the repository's check commands — its test suite and linters — from
      README, AGENTS.md, CONTRIBUTING, a justfile, Makefile, `package.json`
      scripts, or CI config. When the project documents a full CI check, run
      that rather than a developer subset.
   2. Run them in check-only mode. Never pass fix or write flags (`--fix`,
      `--write`, `-w`, `--update-snapshots`, `-u`, `cargo fmt` without
      `--check`, and the like), and never regenerate snapshots or fixtures.
   3. Do not create, edit, or delete files, and never run git commands that
      write refs or the index (`commit`, `push`, `stash`, `switch`,
      `checkout`, `reset`, `add`, …).
   4. If you find no check command, set `passed` to false with one `failures`
      entry whose `command` is `discover check commands` and whose `excerpt`
      says where you looked.

   Return every command you ran in `commands_run`; `passed` is true only if
   every command exited 0; add one `failures` entry per failing command with
   the command and an excerpt of its failing output (the assertion or error
   lines, at most about 40 lines).
   ```

5. Create `.omp/agent/teams/feature-delivery/agents/delivery-reviewer.md`:

   ```markdown
   ---
   name: delivery-reviewer
   description: Reviews the uncommitted change of a delivery run against its PLAN.md and reports severity-ranked findings.
   model:
     - "@delivery_review"
   tools:
     - read
     - grep
     - glob
     - bash
   output:
     properties:
       verdict:
         enum: [approve, changes_requested]
       findings:
         elements:
           properties:
             severity:
               enum: [blocker, major, minor, nit]
             path: { type: string }
             line: { type: number }
             issue: { type: string }
             fix: { type: string }
   ---

   You are the code reviewer on a feature-delivery team. The lead gives you
   the base commit and the `PLAN.md` tasks under review. Review the
   uncommitted change: `git diff <base>` plus the untracked files
   `git status --porcelain` lists (read those files directly). You never talk
   to the human.

   Check, in this order:

   1. Correctness against `PLAN.md`: does the change do what each task says,
      completely, and nothing it does not ask for?
   2. Test adequacy: do tests cover the new behavior, its edge cases and
      failure paths, and would they fail if the behavior broke?
   3. Error handling: are failures surfaced rather than swallowed, and are
      inputs validated at boundaries?
   4. Security-sensitive changes: secrets, injection, unsafe shell or file
      handling, permission changes.
   5. Consistency with the surrounding code: naming, structure, and patterns
      the codebase already uses.

   Severity: `blocker` — the change must not ship as is (wrong or missing
   required behavior, data loss, security hole, broken build); `major` —
   should be fixed before merge; `minor` — worthwhile improvement; `nit` —
   style or wording.

   Read-only: do not create, edit, or delete files, and never run git
   commands that write refs or the index. Use `bash` only for `git diff`,
   `git log`, `git show`, `git status`, and reading.

   Return `verdict` `approve` when there is no `blocker` finding, otherwise
   `changes_requested`, and one `findings` entry per issue with `severity`,
   `path` (repository-relative), `line` (0 when the finding has no single
   line), `issue`, and `fix` (a concrete suggested change).
   ```

6. Verify tracking: `git check-ignore -v --no-index .omp/agent/teams/feature-delivery/package.json .omp/agent/teams/feature-delivery/agents/delivery-builder.md`
   must print nothing and exit 1. If it still reports `.gitignore:…:.omp/agent/*`,
   add `!.omp/agent/teams/**/` immediately after the new line and re-check.
7. Commit: `git add .gitignore .omp/agent/teams/feature-delivery/package.json .omp/agent/teams/feature-delivery/agents/`
   then `git commit` with subject `feat(omp): add delivery team agents`.

#### 3. Add the `/deliver` command

1. Create `.omp/agent/teams/feature-delivery/commands/deliver.md` with exactly
   this content (it encodes the decision's phases, gates, checks, and failure
   policy, plus three behaviors the decision leaves to the command: the
   Direct-path plan header, the Decision-path exit, and resume):

   ````markdown
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

   Commit `PLAN.md` alone with `git commit -m "<subject>" -- PLAN.md` (for the
   removal, `git rm PLAN.md` first). Subjects: when the run implements a
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
   3. Tick the task's checkboxes in `PLAN.md`.
   4. **Check.** Tree snapshot; dispatch `agent: "delivery-tester"` with a
      task naming the `PLAN.md` task just built and `solutionSpace`
      "no fix; run the checks and report". Ref check and tree check.
   5. `passed` false: send the `failures` to the builder, ref check, and
      repeat step 4. When the third check of this task fails (two fix
      attempts spent), ask "Revise PLAN.md" / "Steer the builder" (send the
      human's text to the builder, then repeat step 4) / "End the run".
   6. Set `## Status` to "Task N built and checked" plus anything notable,
      commit `PLAN.md` (status subject), and re-record the ref baseline.

   ## Phase 4 — Review

   1. Read `skill://requesting-code-review`.
   2. Tree snapshot. In one `task` call dispatch `agent: "delivery-reviewer"`
      (task: base `BASE`, `PLAN.md`, every task heading) and
      `agent: "security-reviewer"` (task: review the uncommitted change
      relative to `BASE` — `git diff BASE` plus untracked files — for
      vulnerabilities). Ref check and tree check.
   3. Normalize every finding to severity, path, line, issue, fix:
      `delivery-reviewer` entries as returned; `security-reviewer` entries
      map severity `critical`/`high` → `blocker`, `medium` → `major`, `low` →
      `minor`, `informational` → `nit`, path and line from the first
      `locations` entry, issue from `title` and `summary`, fix from its text
      or "see security finding". Blocker findings are exactly the `blocker`
      entries.
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
      - **Request changes:** send the human's change to the builder, run one
        Phase 3 check and one Phase 4 review round, repeat step 1 (new commits
        on top), and ask Gate 2 again.
      - **Stop:** report the local commits and end; nothing is pushed.
      - **Approve:** commit the removal of `PLAN.md` (done subject), then
        read `skill://pr-create` and follow it. That is the run's first push.
   ````

2. Commit: `git add .omp/agent/teams/feature-delivery/commands/deliver.md`,
   subject `feat(omp): add /deliver workflow command`.

#### 4. Register the package in the default profile only

1. In `.omp/agent/config.yml`, append to the `modelRoles:` map (after
   `commit: anthropic/claude-haiku-5-5:low`, line ~11):

   ```yaml
     delivery_build: anthropic/claude-sonnet-5-5:high
     delivery_test: anthropic/claude-haiku-5-5:auto
     delivery_review: anthropic/claude-opus-5-5:xhigh
   ```

   and insert a new top-level key directly after the `modelRoles:` block,
   before `defaultThinkingLevel: auto`:

   ```yaml
   extensions:
     - ~/.omp/agent/teams/feature-delivery
   ```

   The file has no `extensions:` key today.
2. Append to each of `.omp/profiles/casper/agent/overrides.yml`,
   `.omp/profiles/subconscious/agent/overrides.yml`, and
   `.omp/profiles/baseten/agent/overrides.yml`:

   ```yaml
   # The feature-delivery team needs main's delivery_* modelRoles, which never
   # carry over; opt in by adding an extensions: entry and those roles here.
   extensions: []
   ```

   `scripts/generate-omp-profiles.sh` merges with yq `*` (arrays replace),
   and an empty override array was confirmed to replace the main array
   (`extensions: []` in the render).
3. Run `scripts/generate-omp-profiles.sh`; it rewrites the three
   `.omp/profiles/*/agent/config.yml` files. Then
   `grep -n -A1 '^extensions' .omp/profiles/*/agent/config.yml` must show
   `extensions: []` in all three, and none may contain `delivery_`.
4. Commit `.omp/agent/config.yml`, the three `overrides.yml`, and the three
   rendered `config.yml` together, subject
   `feat(omp): register the feature-delivery package`.

#### 5. Verify (see Verification), then retire the plan and open the PR

1. Run every automated check in **Verification** sections A–C; fix and
   recommit any failure before continuing.
2. Prepare the end-to-end fixture (Verification D, steps 1–2) and leave it in
   place for the user.
3. Retire the plan: `git rm PLAN.md && git commit -m "plan: done 2026-10-11-omp-feature-delivery-team" -m "Co-Authored-By: oh-my-pi <omp@can.ac>" -- PLAN.md`.
4. Push. The remote `feat/omp-feature-delivery-team` still points at the
   pre-rebase commit `a0c14a09ad197ecaa7c73fd78c845dc6c4709bef`, so:
   `git push --force-with-lease=feat/omp-feature-delivery-team:a0c14a09ad197ecaa7c73fd78c845dc6c4709bef -u origin feat/omp-feature-delivery-team`.
   If GitHub answers `fatal error in commit_refs`, retry the same command once.
5. Open the PR with the `pr-create` skill: draft, base
   `docs/omp-feature-delivery-team-decision`, title
   `feat(omp): add feature-delivery agent team`, labels `enhancement` and
   `agent-authored`, assignee `@me`, body starting `Stacked on #528`, with
   Summary, Changes, the commands from Verification A–C with their results,
   and a line stating that the interactive end-to-end run (Verification D)
   is pending with the fixture path.

### Critical files & anchors

- `.omp/agent/config.yml` — `modelRoles:` block (lines ~5–11) and the slot
  before `defaultThinkingLevel`; the main profile the decision targets.
- `.omp/profiles/{casper,subconscious,baseten}/agent/overrides.yml` — where
  `extensions: []` goes; their sibling `config.yml` files are renders, never
  hand-edited.
- `scripts/generate-omp-profiles.sh:45` — the yq merge that empties main's
  `modelRoles` and lets override arrays replace main's.
- `.gitignore` lines ~536–553 — the `!.omp/agent/<dir>/` re-include block;
  hk's `gitignore-sort` step enforces `scripts/sort-gitignore` order.
- `docs/decisions/2026-10-11-omp-feature-delivery-team.md` — clauses 3–5 are
  the source of every rule in `deliver.md` and the agent prompts.

### Verification

Prerequisites (run once, from any directory):

```bash
WT=~/.worktrees/dotfiles/feat/omp-feature-delivery-team
PKG="$WT/.omp/agent/teams/feature-delivery"
SCR="$(mktemp -d)/deliver-verify"; mkdir -p "$SCR/repo/tests"
cat > "$SCR/roles.yml" <<'EOF'
modelRoles:
  delivery_build: anthropic/claude-sonnet-5-5:high
  delivery_test: anthropic/claude-haiku-5-5:auto
  delivery_review: anthropic/claude-opus-5-5:xhigh
EOF
```

Fixture repo (`$SCR/repo`):

- `calc.py`:

  ```python
  def add(a, b):
      """Return a + b."""
      return a + b
  ```

- `tests/__init__.py`: empty.
- `tests/test_calc.py`:

  ```python
  import unittest

  from calc import add


  class AddTest(unittest.TestCase):
      def test_add(self):
          self.assertEqual(add(2, 3), 5)
  ```

- `README.md`:

  ```markdown
  # calc

  Developer test loop: `python3 -m unittest discover -s tests -t .`

  Full CI check (must pass before merge): `./check.sh`
  ```

- `check.sh` (`chmod +x`):

  ```bash
  #!/usr/bin/env bash
  # CI check for this fixture. A verifier arms one forced failure by creating
  # .git/delivery-forced-failure; the check fails until the file is removed.
  set -euo pipefail
  marker="$(git rev-parse --git-dir)/delivery-forced-failure"
  if [[ -e $marker ]]; then
      echo "FORCED FAILURE (verification fixture): remove $marker to clear" >&2
      exit 1
  fi
  python3 -m unittest discover -s tests -t .
  ```

Then `cd "$SCR/repo" && git init -q -b main && git add -A && git commit -qm init && INIT=$(git rev-parse HEAD)`;
`./check.sh` must exit 0.

#### A. Repository gates (cwd `$WT`)

- `hk check .gitignore .omp/agent/config.yml .omp/profiles/*/agent/overrides.yml .omp/profiles/*/agent/config.yml .omp/agent/teams/feature-delivery/package.json`
  exits 0 (covers `gitignore-sort`, `json-format`, `prettier-yaml`,
  `yamllint`, `omp-profiles`).
- `scripts/generate-omp-profiles.sh --check` exits 0, and running
  `scripts/generate-omp-profiles.sh` leaves `git status --porcelain` empty.
- `python3 scripts/agent-harnesses.py generate --check` exits 0.
- `git ls-files .omp/agent/teams` lists exactly `package.json`,
  `agents/delivery-builder.md`, `agents/delivery-reviewer.md`,
  `agents/delivery-tester.md`, and `commands/deliver.md` under
  `.omp/agent/teams/feature-delivery/`.

#### B. Command discovery, no model call (cwd `$SCR/repo`)

Save as `$SCR/probe_commands.py` and run `python3 "$SCR/probe_commands.py" "$PKG"`:

```python
import json
import select
import subprocess
import sys
import time

proc = subprocess.Popen(
    ["omp", "--mode", "rpc", "--no-session", "-e", sys.argv[1]],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
)
proc.stdin.write(json.dumps({"id": "c1", "type": "get_available_commands"}) + "\n")
proc.stdin.flush()
deadline = time.time() + 60
try:
    while time.time() < deadline:
        ready, _, _ = select.select([proc.stdout], [], [], 1)
        if not ready:
            continue
        line = proc.stdout.readline()
        if not line:
            break
        try:
            frame = json.loads(line)
        except ValueError:
            continue
        if frame.get("type") == "response" and frame.get("id") == "c1":
            print(json.dumps([c for c in frame["data"]["commands"] if c["name"] == "deliver"]))
            break
finally:
    proc.kill()
```

Expected: one entry with `"name": "deliver"` and the description from
`deliver.md`'s frontmatter.

#### C. Member probes (headless, cwd `$SCR/repo`; each costs model calls)

Common prefix: `omp -p --no-title --session-dir "$SCR/sessions" -e "$PKG" --config "$SCR/roles.yml"`.
After each probe, locate the child artifacts with
`find "$SCR/sessions" -name '<Name>*'` (a `<Name>.jsonl` transcript and a
`<Name>.json` structured result).

1. **Agent discovery.** Prompt: `Call the task tool exactly once with context "probe" and one task item {agent: "delivery-nonexistent", task: "noop", solutionSpace: "noop"}. Print the tool's error text verbatim and stop.`
   Expected output contains `Unknown agent "delivery-nonexistent". Available:`
   and the names `delivery-builder`, `delivery-tester`, `delivery-reviewer`.
2. **Tester (forced failure, no edit tools).** `touch .git/delivery-forced-failure`.
   Prompt: `Use the task tool once: agent "delivery-tester", name "ProbeTester", context "probe in a scratch repo", task "Before checking, try to create a file named probe.txt using a write or edit tool only, never bash; if you have no such tool, continue. Then check this repository as your instructions say.", solutionSpace "no fix; run the checks and report". Then print the subagent's structured result JSON verbatim.`
   Expected: `ProbeTester.json` (or the printed JSON) has `passed: false` and a
   `failures` entry whose `command` contains `check.sh` and whose `excerpt`
   contains `FORCED FAILURE`; `test ! -e probe.txt`; the marker file still
   exists; `git rev-parse HEAD` equals `$INIT`; `grep -c claude-haiku-5-5`
   on `ProbeTester.jsonl` is ≥ 1. Then `rm .git/delivery-forced-failure`.
3. **Builder.** Prompt: `Use the task tool once: agent "delivery-builder", name "ProbeBuilder", context "probe in a scratch repo; there is no PLAN.md for this probe, treat the task text as the plan task", task "Add sub(a, b) to calc.py returning a - b, with a unittest in tests/test_calc.py.", solutionSpace "one fix: add sub and its test". Then print the subagent's structured result JSON verbatim.`
   Expected: result has `summary`, `files_changed` including `calc.py`,
   non-empty `tests_added`, empty `open_questions`; `./check.sh` exits 0;
   `git rev-parse HEAD` equals `$INIT`; `git status --porcelain` shows
   `calc.py` and `tests/test_calc.py` modified; `ProbeBuilder.jsonl`
   contains `claude-sonnet-5-5`.
4. **Reviewer (no edit tools, tree untouched).** Record
   `H1=$(git diff HEAD --binary | git hash-object --stdin)`. Prompt:
   `Use the task tool once: agent "delivery-reviewer", name "ProbeReviewer", context "probe in a scratch repo", task "Before reviewing, try to create probe2.txt using a write or edit tool only, never bash; if you have no such tool, continue. Base commit <INIT>. Review the uncommitted change; the PLAN.md task is: add sub(a, b) returning a - b with a unittest.", solutionSpace "review; defects unknown". Then print the subagent's structured result JSON verbatim.`
   (substitute `$INIT`). Expected: `verdict` is `approve` or
   `changes_requested`; every finding has `severity` in
   `blocker|major|minor|nit`, `path`, numeric `line`, `issue`, `fix`;
   `test ! -e probe2.txt`; recomputed hash equals `$H1`;
   `ProbeReviewer.jsonl` contains `claude-opus-5-5`.

#### D. End-to-end `/deliver` (interactive; the user runs it, since both gates are human acts)

1. Reset the fixture: `cd "$SCR/repo" && git reset -q --hard "$INIT" && git clean -qfd`.
2. Report to the user: `$SCR/repo`, `$PKG`, and `$SCR/roles.yml`.
3. User: `cd "$SCR/repo" && omp -e "$PKG" --config "$SCR/roles.yml"`, then
   `/deliver add a sub(a, b) function that returns a - b, with tests`.
4. Expected, in order: Phase 0 offers `feat/<slug>` because the repo is on
   `main` (choose create); brainstorm classifies Direct and presents a short
   design (approve); `PLAN.md` appears with `**Decision:** none — Direct path`,
   no commit steps, and `## Status` `Not started.`; Gate 1 is an `ask`
   dialog. Before approving Gate 1, run
   `touch "$SCR/repo/.git/delivery-forced-failure"` in another terminal.
5. After approval: `git log --oneline` shows `docs: add plan`; Agent Hub
   (`Alt+A`) shows `DeliveryBuilder` (sonnet), then a `delivery-tester` run
   that fails with `FORCED FAILURE`, then a second `DeliveryBuilder` turn that
   removes the marker, then a passing tester run; `docs: update plan status`
   commits follow; review dispatches `delivery-reviewer` (opus) and
   `security-reviewer` together; Phase 5 makes local commits only
   (`git remote` is empty, nothing can be pushed) and shows Gate 2.
6. Choose "Approve": a `docs: remove plan` commit appears and `PLAN.md` is
   gone; `pr-create` then stops because the fixture has no GitHub remote —
   expected.
7. Final state: `git log --oneline "$INIT"..HEAD` contains only plan commits
   before the code commits, then the removal commit.

#### E. After merge (user)

From `~` once the stack is merged into `weekend`: start `omp` in any git
repository; `/deliver` autocompletes and `/agents` lists the three
`delivery-*` agents with their `delivery_*` roles resolved.

### Assumptions & contingencies

- If C1 does not list the `delivery-*` agents (extension-package `agents/`
  not discovered), stop and report to the user; do not move the agents into
  `~/.omp/agent/agents/` (the generator prunes that directory, so it would
  need a new decision).
- If a probe transcript shows the parent's default model instead of the
  role's model (the `--config` overlay did not supply `modelRoles`), record it
  in the PR body and confirm model resolution in D via Agent Hub instead.
- If `find "$SCR/sessions" -name '<Name>*'` finds no artifacts, judge the
  probe from the JSON the parent printed and from the file/HEAD checks.
- If the shared harness guard denies writing `.omp/agent/config.yml` or the
  profile files, stop and ask the user to apply step 4's edits.
- If the D run's first tester pass succeeds because the builder ran
  `./check.sh` and cleared the marker itself, repeat D once from step 1; if it
  happens again, note in the PR that the forced-failure loop was not
  observed.

## Status

Steps 1–4 committed; step 5 verification A–C in progress.
