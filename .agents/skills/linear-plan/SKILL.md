---
name: linear-plan
description: Start work on a Linear ticket by gathering context, planning, creating a branch/worktree, implementing, testing, opening a draft PR, and updating Linear. Use when invoked as `$linear-plan` or when the user asks to start a Linear ticket.
---

# linear-plan

Run an end-to-end Linear ticket workflow. If no ticket ID is provided, ask for one. If the user provides only a number, prefix it with `DEVX-`. Optional argument: `--base <branch>`; default is `main`.

## Phase 1: Gather Linear context

Use the `linear-cli:linear-cli` skill before running Linear CLI commands.

Fetch:

```bash
linear issue view <TICKET-ID> --no-pager
linear issue comment list <TICKET-ID> --json
```

Extract title, full description, labels, priority, assignee, state, and all clarifying comment threads.

Assign the issue and move it to in-progress:

```bash
linear issue update <TICKET-ID> --assignee self --state "In Progress"
```

Derive a branch name: `ben/<ticket-id-lowercase>/<3-5-word-title-slug>`.

## Phase 2: Plan

Analyze the codebase enough to identify likely files, patterns, dependencies, and tests.

Create two alternative plans with different trade-off lenses, unless the user has explicitly asked for a single direct plan. Do not spawn subagents unless the user explicitly authorized parallel agents for this task.

Each plan should include:

- Summary.
- Files/modules to change.
- Test plan.
- Trade-offs.
- Risks and open questions.

Present the plans and stop for user selection before implementation.

## Phase 3: Create worktree

After plan approval, create a worktree for the topic branch:

```bash
git fetch origin
repo_root=$(git rev-parse --show-toplevel)
if [ "$repo_root" = "$HOME" ]; then
  path_key="dotfiles"
else
  path_key=$(echo "${repo_root#$HOME/}" | tr '/' '-')
fi
worktree_path="${HOME}/.worktrees/${path_key}/<branch-name>"
git worktree add "${worktree_path}" -b <branch-name> origin/<base-branch>
```

Run subsequent implementation commands from that worktree.

## Phase 4: Post selected plan

Post the selected or synthesized plan to Linear:

```bash
linear issue comment add <TICKET-ID> --body-file /tmp/linear-plan-<TICKET-ID>.md
```

Save the plan comment URL or ID for later test-result replies.

## Phase 5: Implement and commit

Implement the approved plan. Commit in logical groups with conventional commit messages and uppercase ticket references such as `Resolves DEVX-696` or `Part of DEVX-696`.

## Phase 6: Push and open draft PR

Push:

```bash
git push -u origin <branch-name>
```

Create a draft PR. Use `$pr-create` when the repo's standard PR style is sufficient; otherwise create with ticket-specific labels such as `D-skip-changelog`, `K-*`, `A-*`, `S-*`, and `P-*` as appropriate.

## Phase 7: Test

Run the approved test plan. Fix straightforward failures and commit fixes separately. If a failure is ambiguous or high-risk, pause and report.

## Phase 8: Update Linear

Reply to the plan thread with test results and PR link. Update the PR description with completed test-plan items. Final report must include PR URL, test status, and any manual follow-up.
