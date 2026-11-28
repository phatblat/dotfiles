---
name: nightly-batch
description: "Use when the user asks to run tonight's batch, the nightly batch, or the next delivery batch in a repo that has docs/runbooks/nightly-batch.md."
---

# Nightly batch

This skill is a trigger. It holds no procedure and no state: both live in the repository.

1. Confirm the current repository has `docs/runbooks/nightly-batch.md`. If it does not, stop and say so; do not improvise a procedure.
2. Read the repository's `AGENTS.md`, then `docs/runbooks/nightly-batch.md`, in full.
3. Follow the runbook exactly, from its first step to its last. Where this skill, any other skill, or your own habits differ from the runbook, the runbook wins.
4. The budget, the point value and what the previous batch left are in the repository's batch log, which the runbook tells you to read. Do not take them from chat history or memory. If the user gave a budget in the message that invoked this skill, use it for this batch and record in the batch log that the owner set it.
5. Do not ask the user questions mid-run. A step that needs the owner is a stop condition the runbook describes: record it and move on as the runbook says.
6. End with the short report the runbook's last step asks for.
