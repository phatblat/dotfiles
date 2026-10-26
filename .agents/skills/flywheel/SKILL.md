---
name: flywheel
description: "Define, review, repair, or set up a repository's agent harness data flywheel: the learning loop that records agent sessions, learns from them by analysis or by replaying them on better models, applies the lessons to instructions, skills, hooks, and memory, prunes scaffolding newer models no longer need, and tunes the loop itself. Use when a repo documents a flywheel (docs/flywheel.md) that needs review or repair, when a repo has no learning loop and needs its first one, or when the user asks how agents should learn across sessions, keep memory, run retros or evals on recorded sessions, or remove harness scaffolding as models improve."
license: MIT
metadata:
  author: phatblat
---

# flywheel

An agent without a flywheel is limited to a single session: what it learns
ends when the session does. The flywheel carries experience forward. Record
what agents did, learn from it (analyze it, or replay it on a better model),
apply the lessons to the harness, prune scaffolding the model no longer
needs, then measure and tune the loop itself and turn it again.

Every harness records sessions and stores context differently. What matters
is whether the repo's flywheel is **documented** and **implemented**. This
skill reviews and repairs a documented flywheel, or guides a repo to its
first one.

The model adapts Jediah Katz's harness data flywheel
([Is the Agent Harness Dead?](https://www.youtube.com/watch?v=7Y4sbZgBdnc),
presented in Turing Post's
[AI Models Are Eating Their Harnesses. Now What?](https://www.youtube.com/watch?v=pEHfZUrahGc)):
the harness enables difficult tasks → agent usage → training experience →
better models → some scaffolding removed → the harness unlocks the next
frontier.

## The six stages

| # | Stage | Turns the loop by | Katz step |
|---|---|---|---|
| 1 | Enable | Instructions, skills, tools, hooks, and guardrails that let agents attempt harder tasks | 01 Harness enables difficult tasks |
| 2 | Record | Keeping sessions, outcomes, friction, and scaffold firings after the session ends | 02 Agent usage |
| 3 | Learn | Turning records into evidence-backed lessons: analysis, retros, or replaying fixed cases on a better model | 03 Training experience |
| 4 | Apply | Feeding lessons into instructions, skills, hooks, memory, and model choice, behind human review | 04 Better models |
| 5 | Prune | Removing scaffolding that stopped firing or passed an ablation | 05 Some scaffolding removed |
| 6 | Tune | Measuring the loop itself (coverage, cadence, yield, regressions, cost per task) and adjusting it | The loop's own loop |

`references/stages.md` defines what "implemented" means for each stage, the
evidence to check, where to look for existing pieces, and common breaks.
Read it before judging or proposing any stage.

Never prune what a model cannot absorb: runtime and infrastructure, trust
and security (scoped permissions, secret handling, spend limits,
destructive-action guards), and efficiency controls.

## Arguments

Whitespace-split `$ARGUMENTS`, order-independent:

- `review` or `setup` forces the mode. Absent: detect it (below).
- `since:N` sets the evidence window in days. Defaults to the doc's `Evidence window` in review mode (fallback `30`), or `30` in setup mode.
- Any other token: stop and print the valid tokens. Do not fuzzy-match.

## Detect the flywheel doc

Search the repo root in this order. The first hit is canonical:

1. `docs/flywheel.md`
2. `FLYWHEEL.md`
3. Any other tracked `*flywheel*.md` outside skill and adapter trees (`git ls-files ':(glob)**/*flywheel*.md' ':!docs/flywheel.md' ':!FLYWHEEL.md' ':(glob,exclude)**/.agents/**' ':(glob,exclude)**/.claude/**'`)
4. A level 1-3 heading containing `flywheel` or `learning loop`
   (case-insensitive) in `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`,
   `.github/copilot-instructions.md`, or `README.md`

Found: review mode. Not found: setup mode. More than one hit: review the
canonical one and report the rest as a `duplicate` finding. A rule 4
section whose body only points to a doc found by rules 1-3 (such as the
setup pointer section below) is a pointer, not a hit.

`setup` forced while a doc exists: name the doc and switch to review. Never
overwrite a flywheel doc. `review` forced with no doc: say so and offer
setup.

## Evidence and privacy rules

- Session data can hold prompts, code, secrets, and credentials. Keep
  analysis local and aggregate-only: never load raw transcripts into
  context, never send them to an external API, never commit transcript
  content.
- Where `~/scripts/harness-sessions.py` exists (phatblat dotfiles) and the
  repo under review is the `$HOME` dotfiles checkout itself, run
  `python3 ~/scripts/harness-sessions.py <slugs> --since <N> --json` as the
  session evidence source (pass only supported `<slugs>` from `references/harness-signals.md`, omitting `-`),
  under the rules in
  `~/.agents/skills/optimize-harness/references/session-usage-evidence.md`
  (`harness-sessions.py` is `$HOME`-scoped across user-level stores, not
  repo-scoped). In any other repo, or when the script is absent, check only
  session store existence, file counts, and newest timestamps
  (`references/harness-signals.md`).
- Run a documented command only when it is read-only: a scan, `status`,
  `list`, `--check`, or `--dry-run`. For any other command, confirm only that
  its binary (`command -v`) or recipe (`just --list`) exists.
- `unknown/not observed` is never `unused`. A finding with no evidence is
  dropped, not softened.

## Review mode

1. Read the canonical doc. Map each section to one of the six stages. A
   stage with no section is `missing`. A doc not built from
   `assets/flywheel-template.md` is still reviewable: map its sections by
   meaning and list any that map to no stage.
2. Check each stage with the evidence checks in `references/stages.md`:
   - every path in Implementation exists (repo-relative or `~`-expanded);
   - every command in Implementation resolves, under the rules above;
   - every hook script it names is either referenced by that harness's hook
     config (JSON, TOML, YAML, or `crushrc` `hook add`) or lives in that
     harness's auto-discovered extension/hook directory
     (`references/harness-signals.md`);
   - for stages 2-6, Evidence satisfies that stage's recency check within
     `since:N` days (`references/stages.md`: file mtime,
     `git log -1 --format=%cs -- <path>`, or the newest Cycle log date).
     No Evidence location declared counts as no run for stages 2-6.
     `Enable` (stage 1) has no `since:N` recency requirement.
3. Assign each stage one observed status (table below).
4. Check the Scaffolding register against `references/stages.md` § 5.
5. Rate every finding (table below).
6. Print the review report. Then ask one multi-select question that lists
   every finding as a repair option, plus the option "Record this review in
   the Cycle log only". Change nothing before the answer.
7. Repair only the chosen findings, with targeted edits: fix a wrong path or
   command, wire a missing hook, add a `missing` stage section as `planned`,
   or correct a `Status` field (`planned` or `implemented` only). Never edit files that define the agent's own
   permissions or guardrails (on phatblat dotfiles, `[control_plane]` in
   `~/.config/ness/policy.toml`). Write a patch for the user instead. Never
   remove a scaffold without an ablation result.
8. If anything was repaired or recording was chosen: rerun the step 2 checks
   for each repaired stage, set `Last reviewed` to today, and append this
   Cycle log row. If nothing was chosen, write nothing.

   ```markdown
   |<date>|review|<n> High, <n> Medium, <n> Low|<repairs or none>|<metrics>|<next action>|
   ```

### Observed status

| Status | Meaning |
|---|---|
| `ok` | Implemented, wired, and ran within the window |
| `stale` | Implemented and wired, with no evidence of a run within the window |
| `broken` | A path, command, or hook it relies on is missing or fails |
| `documented-only` | Described, with nothing implementing it (`Implementation: none`, or a `planned` stage whose paths do not yet exist) |
| `missing` | No section for the stage |

Declared `Status` is `implemented` or `planned`: `implemented` agrees with `ok`
and `planned` agrees with `documented-only`.

### Severity

| Finding | Severity |
|---|---|
| `broken` stage | High |
| `missing` or `documented-only` Record, Learn, or Apply | High: the loop cannot turn |
| Record stage writes transcript content to a tracked path | High |
| A never-prune control listed in the Scaffolding register | High |
| `missing` or `documented-only` Enable, Prune, or Tune | Medium |
| `stale` stage | Medium |
| Declared Status disagrees with observed status | Medium |
| `duplicate` flywheel doc | Medium |
| Scaffold with no firing signal | Low: add a firing signal |
| Scaffold with a firing signal and no firing in the window | Low: ablation candidate |

### Review report

```markdown
## Flywheel Review: <repo> (<YYYY-MM-DD>, window <N>d)

Doc: `<path>` · Harnesses: <list>

|#|Stage|Declared|Observed|Evidence|
|---|---|---|---|---|

### Findings

|#|Severity|Stage|Finding|Evidence|Repair|
|---|---|---|---|---|---|

### Next turn of the loop

- <the single highest-leverage action>
```

## Setup mode

1. **Harnesses.** Detect the repo-root markers in
   `references/harness-signals.md`. If none are found, ask which harnesses
   the team uses.
2. **Existing pieces.** For each stage, search the repo using that stage's
   search hints in `references/stages.md`. Anything already turning the
   loop is reused before anything new is proposed.
3. **Proposal.** Present one minimal mechanism per stage. Prefer existing
   pieces, then harness-native features (`references/harness-signals.md`),
   then new code. Use the table below. List every file setup will write.
   Ask for approval. Apply any requested adjustments and present again.
4. **Doc.** Copy `assets/flywheel-template.md` to `docs/flywheel.md`
   (create `docs/` if absent) and fill in every placeholder. A stage whose
   mechanism already runs gets `implemented`; every other stage gets
   `planned` with `Implementation: none` and `Evidence: none` until implemented. Seed the Scaffolding register with the nudge or reminder hooks
   and model-correcting instructions found in step 2. Add the first Cycle
   log row:
   `| <date> | setup | <n> existing pieces found | created docs/flywheel.md | <metrics> | <first planned stage> |`.
5. **Pointer.** Append the pointer section below to the first of these that
   exists: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`,
   `.github/copilot-instructions.md`. If none exists, create `AGENTS.md`
   containing only the pointer section. If `docs/charter.md` has an
   `## Artifacts` table, append the row
   ``| Flywheel | `docs/flywheel.md` | agent learning loop; maintained with the flywheel skill |``.
6. **Prompts.** For each `planned` stage, in stage order, print its prompt
   from `references/setup-prompts.md` with every placeholder filled from
   this repo. Each prompt is self-contained, so it can be pasted into a
   fresh agent session.

Proposal table (step 3):

| Stage | Proposed mechanism | Reuses | Status after setup |
|---|---|---|---|

Pointer section:

```markdown
## Agent Flywheel

The agent learning loop for this repo is documented in `docs/flywheel.md`.
Read it before changing agent instructions, skills, hooks, or memory, and
add a Cycle log row whenever you run one of its stages.
```

## Common mistakes

- Treating a memory file or a transcript directory as a flywheel. Storage is
  only the Record stage. Without Learn and Apply, the loop does not turn.
- Calling a harness-native learning feature implemented because it exists.
  It counts only when the doc names it and its evidence shows a run.
- Pruning a guardrail because a newer model "should" handle it. Prune only
  on a stopped firing signal or an ablation that holds success, cost,
  latency, and safety.
- Letting the loop edit its own guardrails. Apply-stage changes go through
  human review, and policy files are patched by hand.
