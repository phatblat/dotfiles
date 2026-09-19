---
name: subagent-output-schema-contract
description: "Use when spawning a task()/agent()/workpool() subagent with an outputSchema, to reduce yield-tool retry failures by stating the exact result envelope and required fields in the task prompt."
---

## Problem

When a subagent is spawned with an `outputSchema`, it must finish by calling the hidden `yield` tool with a result matching that schema. On a cold turn, models frequently get the wrapper or field names wrong on the first attempt:

- Forgetting the required envelope: the result must be `{"data": <schema-matching object>}` on success or `{"error": "<message>"}` on failure — not the bare object.
- Missing or misnamed required fields (e.g. a review-finding schema needing `title`/`body`/`priority`/`confidence`/`file_path`/`line_start`/`line_end`, or a research schema needing `summary`/`architecture`/`files`).
- Using `"result"` as an incremental-yield section label instead of one of the schema's own top-level property names.

OMP's built-in retry loop (`MAX_YIELD_RETRIES=3`) recovers from this ~99% of the time, so it rarely loses work — but each failure burns one extra subagent turn (tokens + latency) that a clearer prompt avoids.

## Practice

When calling `task()`, `agent()`, or `workpool()` with an `outputSchema`, append an explicit output-contract line to the `task`/prompt text (not just relying on the schema being attached mechanically):

```
Output contract: finish by calling yield with {"data": {...}} on success (or {"error": "<message>"} if you cannot complete the task). The data object must include these required fields verbatim: <list the schema's required top-level field names>. Do not wrap the object in an extra "result" key.
```

For schemas with nested/array sections (e.g. a `findings[]` array of review items), spell out the nested required fields too, since these are the most common source of mismatch.

This does not require any OMP config change — it is a parent-side prompting habit, applied every time an `outputSchema` is supplied to a spawned subagent.

## Non-fix

Do not attempt to "fix" this via `~/.omp/agent/config.yml` or hooks — the yield envelope format and retry mechanism are implemented in upstream `oh-my-pi`'s task executor (`packages/coding-agent/src/task/executor.ts`), not in user config. There is no dotfiles-side lever.
