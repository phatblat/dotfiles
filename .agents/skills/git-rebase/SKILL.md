---
name: git-rebase
description: Rebase the current branch onto a target branch using safety checks, backup branches, and an appropriate rebase strategy. Use when invoked as `$git-rebase` or when the user asks to update/rebase a branch.
---

# git-rebase

Rebase the current branch onto a target branch. If the user provides an argument, use it as the target branch; otherwise use the remote default branch.

## Workflow

1. Gather context:

   ```bash
   subject=$(git branch --show-current)
   target=<argument-or-default-branch>
   git status --porcelain=v1
   ```

2. Stop if:

   - `subject` equals `target`.
   - The working tree is dirty. Tell the user to commit or stash first.

3. Fetch and update target:

   ```bash
   git fetch origin
   git fetch origin "${target}:${target}"
   ```

   If the local target cannot fast-forward, stop and report.

4. Create a backup branch:

   ```bash
   git branch "${subject}.bak"
   ```

   If it already exists, ask whether to overwrite it or abort.

5. Analyze divergence:

   ```bash
   merge_base=$(git merge-base HEAD "${target}")
   git log --oneline "${merge_base}..HEAD"
   git log --oneline "${merge_base}..${target}"
   git diff --name-only "${merge_base}" HEAD
   git diff --name-only "${merge_base}" "${target}"
   git merge-base --is-ancestor "${merge_base}" "${target}" && echo base_on_target=yes || echo base_on_target=no
   ```

6. Choose strategy:

   | Condition | Strategy |
   | --- | --- |
   | Target has at least 20 commits and at least 3 overlapping files | cherry-pick |
   | Merge-base is not on target lineage | `rebase --onto` |
   | Otherwise | simple rebase |

   Show the analysis and selected strategy before proceeding.

7. Execute:

   - Simple: `git rebase "${target}"`
   - Onto: `git rebase --onto "${target}" "${merge_base}" HEAD`
   - Cherry-pick: create `<subject>__cherrypick__` from target and cherry-pick subject commits oldest-first.

8. On conflicts, resolve automatically and continue; the Step 4 backup and `rerere` make this recoverable:

   - Apply any recorded `rerere` resolution.
   - Filtered machine-state files (e.g. `.codex/*.config.toml` trust hashes): keep ours (`git checkout --ours`); the clean filter re-normalizes the blob on `git add`.
   - Dependency/version bumps: keep the higher version, or `--skip` the commit if the bump is already upstream.
   - Deliberate config updates: take the incoming value (`git checkout --theirs`).
   - Generated artifacts: regenerate from source.

   Stage each fix, verify no conflict markers remain, then `--continue` (or `--skip` if the commit became empty). Pause and ask **only** for genuine semantic collisions in hand-written source — never guess those. Report how each conflict was resolved.

9. After success, set tracking and push:

   ```bash
   git branch --set-upstream-to="origin/${subject}" "${subject}"
   git push --force-with-lease -u origin "${subject}:${subject}"
   git branch -vv
   ```

10. Report strategy, branch, tracking, and backup branch. Keep `<subject>.bak` until the user confirms cleanup.
