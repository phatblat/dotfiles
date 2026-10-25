# Flywheel Stages

Each stage below gives its purpose, what "implemented" means, the evidence
check used in review, search hints for finding existing pieces during
setup, a minimal first mechanism, and common breaks.

A model lab closes Katz's loop by retraining: usage becomes training
experience, which becomes better models. A repo cannot retrain the model.
Its Learn stage turns usage into lessons the harness can absorb now
(instructions, skills, hooks, memory) and into replay cases that measure
each new model. Its Apply stage is where those lessons and better models
enter the harness.

## 1. Enable

- **Purpose:** the harness surface that lets agents attempt tasks the bare
  model cannot: instructions, skills, tools and MCP servers, hooks,
  permissions, and guardrails.
- **Implemented means:** the doc lists the instruction files, skills, MCP
  servers, and hooks agents load in this repo, and every listed path
  exists.
- **Evidence check:** every Implementation path exists, every hook or
  MCP config file parses (JSON, TOML, YAML, or `crushrc` `hook add`), and
  every hook script is either referenced by a config file or located in an
  auto-discovered extension/hook directory.
- **Search hints:** `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`,
  `.github/copilot-instructions.md`, `.cursor/rules/`, `.agents/skills/`,
  `.claude/skills/`, `.claude/settings.json` `hooks`, `.codex/hooks.json`,
  `.omp/extensions/`, `.mcp.json`.
- **Minimal first mechanism:** record what already exists. Add nothing.
- **Common breaks:** instructions that reference removed paths, skills whose
  descriptions never trigger, and hooks that point at missing scripts.

## 2. Record

- **Purpose:** experience outlives the session. Capture sessions,
  outcomes, friction, and scaffold firings.
- **Implemented means:**
  1. every harness in use has a known session store whose retention covers
     at least one evidence window;
  2. each task leaves an outcome signal: success, partial, failed, or
     abandoned, plus whether the user corrected the agent;
  3. every Scaffolding register row with a firing signal has its firings
     logged with timestamps.
- **Evidence check:** for each harness in use, the session store exists and
  its newest file falls within the window. The outcome ledger's newest entry
  falls within the window. Coverage is the number of harnesses with both,
  over the number of harnesses in use.
- **Privacy:** raw transcripts stay in each harness's own untracked store.
  Anything committed is an aggregate or a human-reviewed summary.
- **Search hints:** the session stores in `harness-signals.md`,
  `SessionEnd` and `Stop` hooks, session export scripts, `docs/handoffs/`,
  and retro notes.
- **Minimal first mechanism:** rely on native session stores. Add one
  end-of-session hook, or a manual end-of-task step for harnesses without
  hooks, that appends a JSON line with the fields `date`, `harness`,
  `session_id`, `task` (at most 80 characters, no secrets), `outcome`
  (`success`, `partial`, `failed`, or `abandoned`), and `corrected`
  (`true`/`false`) to
  `${XDG_STATE_HOME:-$HOME/.local/state}/flywheel/<repo>/outcomes.jsonl`,
  outside git.
- **Common breaks:**
  - retention shorter than the cycle, so sessions are deleted before Learn
    runs;
  - a store moved by an environment override;
  - a hook wired in one harness but not another;
  - only transcripts recorded, with no outcomes.

## 3. Learn

- **Purpose:** records become evidence-backed lessons. There are two
  mechanisms:
  - **Analysis:** aggregate scans and retros on recurring friction.
  - **Replay:** fixed cases rerun on a new model or config.
- **Implemented means:** a repeatable procedure runs on a declared cadence
  and writes dated findings where Apply reads them. Each finding carries
  evidence (counts, session IDs, dates) and a proposed harness change.
- **Replay rules:**
  - A case is a prompt, a starting commit, and a deterministic check.
  - Run each case at least 3 times per config, because agent output varies.
  - Hold the budget fixed.
  - Record success, tokens or cost, wall time, interventions, and denied
    actions.
- **Evidence check:** the newest findings file is dated within the window.
- **Search hints:** `evals/`, `*eval*`, `retro`, `postmortem`,
  `optimize-harness`, CI jobs that run agents, and `docs/decisions/`.
- **Minimal first mechanism:** a retro over the outcome ledger and session
  aggregates once per window, writing one dated findings file. Add replay
  once 3 to 5 cases exist.
- **Common breaks:**
  - findings without evidence;
  - analysis that feeds raw transcripts to a model;
  - replay with a single run per case;
  - cases that depend on the network or on the clock.

## 4. Apply

- **Purpose:** lessons change the harness: instructions, skills, hooks,
  memory, and model choice after a replay.
- **Implemented means:**
  - every finding gets a disposition: applied, with a commit or PR link, or
    declined, with a reason;
  - every harness change cites the finding behind it;
  - a human reviews each change before it merges.
- **Memory:** harness-native memory counts when entries are durable facts,
  are reviewed, and hold no secrets or transcript excerpts.
- **Evidence check:** commits within the window touch instruction, skill,
  or hook paths and cite a finding, and every finding in the newest
  findings file has a disposition in the Cycle log.
- **Search hints:** `git log` on instruction, skill, and hook paths, the
  `retro` skill, and decision records.
- **Minimal first mechanism:** each Learn finding becomes one PR or one
  declined entry in the Cycle log.
- **Common breaks:**
  - findings pile up with no disposition;
  - edits have no evidence trail;
  - agents edit their own guardrails;
  - memory collects contradictory or stale entries.

## 5. Prune

- **Purpose:** remove scaffolding the model no longer needs, so the harness
  stays lean enough to take on the next frontier.
- **Scaffold:** an instruction, hook, tool, or nudge that compensates for a
  model weakness rather than enforcing a boundary.
- **Register rule:** every scaffold has a firing signal, meaning an
  observable log line, counter, or event. A row with no signal cannot be
  pruned on evidence (Low finding: add one).
- **Removal rule:** when a scaffold has not fired within the window, or
  when an ablation passes, propose its removal as a PR. Never remove one
  automatically. An ablation means:
  1. remove only that scaffold;
  2. rerun the same cases at least 3 times, with model and budget fixed;
  3. it passes only if success, cost, latency, and safety checks all hold.
- **Never prune:** runtime and infrastructure; trust and security
  (permissions, secret handling, spend limits, destructive-action guards);
  efficiency controls (caching, model routing). These are boundaries, not
  scaffolding, and never belong in the register (High finding if listed).
- **Evidence check:** every register row has a firing signal and a Last
  fired date. Rows with no firing in the window are flagged as ablation
  candidates.
- **Search hints:** hooks that warn, nudge, or remind; instructions that
  correct a model habit ("always", "never forget", "remember to", "make
  sure"); prompt shims; and automatic retries.
- **Minimal first mechanism:** register the existing nudge hooks and
  model-correcting instructions with their firing signals, and review the
  register at each model upgrade.
- **Common breaks:**
  - no register;
  - scaffolds with no signal;
  - removal without an ablation;
  - a guardrail mistaken for scaffolding.

## 6. Tune

- **Purpose:** the flywheel is itself a system to measure and optimize.
- **Metrics:**
  - **Coverage:** harnesses with a working Record mechanism, over
    harnesses in use.
  - **Cadence:** days since each stage last ran, against its declared
    Cadence.
  - **Yield:** findings applied, over findings produced, per cycle.
  - **Regressions:** applied changes reverted within the window
    (`git log --since=<N>.days -i --grep=revert` on the touched paths).
  - **Cost per task:** tokens or spend per task, where the harness reports
    it. Harness choice changes cost per task even when success rates
    match.
- **Implemented means:** each cycle ends with a Cycle log row that records
  every metric (as `unknown` when not measurable) and one decision about
  the loop: keep it, change a stage's mechanism, or change a cadence.
- **Evidence check:** the newest Cycle log row is dated within the window,
  with Metrics and Next filled in.
- **Search hints:** existing dashboards or reports on agent cost, and CI
  jobs that summarize agent runs.
- **Minimal first mechanism:** the Cycle log itself, with metrics computed
  by hand from the doc and `git log`.
- **Common breaks:**
  - the Cycle log is never updated;
  - metrics are reported without denominators;
  - tuning only ever adds stages and never simplifies.

## Sources

- Jediah Katz, "Is the Agent Harness Dead?", AI Engineer, 2026-10-19:
  https://www.youtube.com/watch?v=7Y4sbZgBdnc
- Turing Post, "AI Models Are Eating Their Harnesses. Now What?",
  2026-10-17: https://www.youtube.com/watch?v=pEHfZUrahGc
