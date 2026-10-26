# Setup Prompts

One prompt per stage. Setup prints the prompt for each `planned` stage, in
stage order, with these placeholders filled in:

| Placeholder | Value |
|---|---|
| `<REPO>` | the repo directory name |
| `<HARNESSES>` | the harnesses in use, comma-separated |
| `<WINDOW_DAYS>` | the evidence window in days |
| `<MECHANISM>` | the approved mechanism for the stage, from the setup proposal |
| `<REUSE>` | the existing pieces found for the stage, or `none` |

## 1. Enable

```text
You are implementing the Enable stage of this repo's agent flywheel, documented in docs/flywheel.md.

Goal: agents working in <REPO> load an accurate, minimal harness for <HARNESSES>: instructions, skills, tools, hooks, and guardrails.
Approved mechanism: <MECHANISM>
Reuse first: <REUSE>

1. Inventory the instruction files, skills, MCP servers, and hooks each harness loads in this repo. List each path (repo-relative or ~-expanded) in the Enable section's Implementation and Evidence fields.
2. Fix any instruction or skill that references a path or command that no longer exists.
3. Do not add an instruction that compensates for a model weakness without adding a Scaffolding register row with its firing signal.

Done when: every path in the Enable section exists, each harness's hook config parses, Implementation and Evidence are populated, the Status field reads implemented, and the Cycle log has a row dated today.
```

## 2. Record

```text
You are implementing the Record stage of this repo's agent flywheel, documented in docs/flywheel.md.

Goal: experience from every agent session in <HARNESSES> outlives the session.
Approved mechanism: <MECHANISM>
Reuse first: <REUSE>

1. Confirm each harness's session store location and retention from its primary documentation. Retention must cover at least <WINDOW_DAYS> days. If it does not, change the retention setting or record the gap in the doc.
2. Capture one outcome record per task as a JSON line with the fields date, harness, session_id, task (at most 80 characters, no secrets), outcome (success, partial, failed, or abandoned), and corrected (true or false). Append it to ~/.local/state/flywheel/<REPO>/outcomes.jsonl (or $XDG_STATE_HOME/flywheel/<REPO>/outcomes.jsonl, recorded as a ~-expanded path in docs/flywheel.md), outside git. Prefer an end-of-session hook. Use a documented manual step for any harness without one.
3. For each Scaffolding register row, make its firing observable with a timestamped log line, counter, or event.
4. Never copy transcript content, prompts, or tool output into tracked files.

Done when: one new session in each harness leaves an outcome record, the Record section's Implementation and Evidence fields list the stores, hooks, and ledger path (repo-relative or ~-expanded), the Status field reads implemented, and the Cycle log has a row dated today.
```

## 3. Learn

```text
You are implementing the Learn stage of this repo's agent flywheel, documented in docs/flywheel.md.

Goal: recorded experience becomes lessons backed by evidence.
Approved mechanism: <MECHANISM>
Reuse first: <REUSE>

1. Write a repeatable analysis procedure (a script, a task-runner recipe, or a skill). It reads the outcome ledger and session aggregates for the last <WINDOW_DAYS> days and reports outcome counts by harness, the correction rate, the most frequent tool errors and permission denials, and which scaffolds fired. It reads aggregates only and never loads raw transcripts into a model.
2. Each finding states its evidence (counts, session IDs, dates) and a proposed harness change.
3. Optional replay: keep 3 to 5 fixed cases, each a prompt, a starting commit, and a deterministic check. To compare a new model or config, run each case at least 3 times per config with the budget held fixed. Record success, tokens or cost, wall time, interventions, and denied actions.
4. Write findings to a dated file that the Apply stage reads, and record the analysis command/script in the Learn section's Implementation field and the findings path in its Evidence field (repo-relative or ~-expanded).

Done when: one run produces a dated findings file with at least one evidenced finding, or an explicit "no findings" with the counts, Implementation and Evidence are populated, the Status field reads implemented, and the Cycle log has a row dated today.
```

## 4. Apply

```text
You are implementing the Apply stage of this repo's agent flywheel, documented in docs/flywheel.md.

Goal: every Learn finding either changes the harness or is explicitly declined.
Approved mechanism: <MECHANISM>
Reuse first: <REUSE>

1. For each open finding, make the smallest harness change that addresses it: an instruction, a skill, a hook, a memory entry, or a model choice. Use one commit or PR per finding, and cite the finding in the message.
2. A human reviews every change before it merges. Never change files that define the agent's own permissions or guardrails. Write those changes as a patch for a human to apply.
3. Memory entries hold durable facts only: no secrets and no transcript excerpts.
4. Record each finding's disposition in the Cycle log's Changes column: applied, with a commit link, or declined, with a reason. Populate the Apply section's Implementation and Evidence fields in docs/flywheel.md with repo-relative or ~-expanded paths.

Done when: no finding in the latest findings file lacks a disposition, Implementation and Evidence are populated, the Status field reads implemented, and the Cycle log has a row dated today.
```

## 5. Prune

```text
You are implementing the Prune stage of this repo's agent flywheel, documented in docs/flywheel.md.

Goal: scaffolding the current model no longer needs is removed, on evidence.
Approved mechanism: <MECHANISM>
Reuse first: <REUSE>

1. Fill the Scaffolding register with every instruction, hook, tool, or nudge that compensates for a model weakness. Give each its path, what it compensates for, the date it was added, its firing signal, when it last fired, and its removal criterion. Do not list runtime, security, permission, secret-handling, spend-limit, or efficiency controls. They are boundaries, not scaffolding.
2. At each model or harness upgrade, and at least every <WINDOW_DAYS> days, flag rows whose firing signal shows no firing in the window.
3. Before removing a flagged scaffold, run an ablation. Remove only that scaffold and rerun the same cases at least 3 times with model and budget fixed. Keep the removal only if success, cost, latency, and safety checks all hold.
4. Propose each removal as its own PR with the ablation result attached. Populate the Prune section's Implementation and Evidence fields in docs/flywheel.md with repo-relative or ~-expanded paths.

Done when: every register row has a firing signal and a removal criterion, Implementation and Evidence are populated, the Status field reads implemented, and the Cycle log has a row dated today.
```

## 6. Tune

```text
You are implementing the Tune stage of this repo's agent flywheel, documented in docs/flywheel.md.

Goal: the loop itself is measured and improved each cycle.
Approved mechanism: <MECHANISM>
Reuse first: <REUSE>

1. At the end of each cycle, compute these metrics and record them in the Cycle log's Metrics column:
   - coverage: harnesses with a working Record mechanism, over harnesses in use
   - cadence: days since each stage last ran, against its declared cadence
   - yield: findings applied, over findings produced
   - regressions: applied changes reverted within the window
   - cost per task, when the harness reports it
   Write unknown for any metric you cannot measure. Never estimate one.
2. Make at least one decision about the loop per cycle: keep it as is, change a stage's mechanism, or change a cadence. Record the decision in the Next column.
3. Populate the Tune section's Implementation and Evidence fields in docs/flywheel.md with repo-relative or ~-expanded paths, then run the flywheel skill's review mode at the end of each cycle and repair its High findings first.

Done when: the latest Cycle log row has every metric (or unknown) and a decision, Implementation and Evidence are populated, the Status field reads implemented, and review reports no High finding for this stage.
```
