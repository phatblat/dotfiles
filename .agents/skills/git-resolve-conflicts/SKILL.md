---
name: git-resolve-conflicts
description: Resolve unmerged paths from a pending merge, rebase, cherry-pick, or stash pop, then continue the operation and commit. Use when invoked as `$git-resolve-conflicts` or when the user asks to resolve conflicts and commit.
disable-model-invocation: true
---

# git-resolve-conflicts

Resolve every unmerged path in the current worktree, continue whatever git operation is pending, and commit the result.

## Workflow

1. Inspect state:

   ```bash
   git status
   git ls-files -u
   ```

   Identify the pending operation:
   - `MERGE_HEAD` / `rebase-merge` / `rebase-apply` / `CHERRY_PICK_HEAD` / `REVERT_HEAD` present -> merge/rebase/cherry-pick/revert.
   - Otherwise (unmerged paths but no HEAD pointer) -> likely a stash pop conflict or manual merge; resolve in place.

   List the conflicted files: `git diff --name-only --diff-filter=U`.

2. For each conflicted file, inspect the three stages:

   ```bash
   git show :1:<path>   # base
   git show :2:<path>   # ours (HEAD / current branch)
   git show :3:<path>   # theirs (incoming / stashed)
   ```

   And the working-tree conflict markers.

3. Resolve per file using these rules:

   - Machine-generated / filtered state files (e.g. `.codex/*.config.toml` trust hashes, lockfiles): keep ours (`git checkout --ours <path>`); the clean filter re-normalizes on `git add`.
   - Dependency / version bumps: keep the higher version; if already upstream, `--skip` the commit.
   - Deliberate config updates (incoming value intended): take theirs (`git checkout --theirs <path>`).
   - Generated artifacts: regenerate from source, then stage.
   - Stash-pop conflicts where the stash is stale (its changes already present in HEAD): keep ours for every file; the stash adds nothing.
   - Hand-written source with a genuine semantic collision: pause and ask the user before choosing; never guess.
   - JSON / JSONL / TOML data files with duplicate or contradictory rows: drop duplicates and obviously bogus rows (downgrades, empty values, format-only changes), keeping one clean copy of each legitimate entry.

   When a file has conflict markers, remove the markers and keep the chosen side's content. For 3-way markers (`<<<<<<<` / `|||||||` / `=======` / `>>>>>>>`), select the intended side and delete the marker lines.

4. Stage every resolved file:

   ```bash
   git add <path> ...
   ```

5. Verify no conflict markers remain:

   ```bash
   git diff --check
   ```

   If any remain, fix before continuing.

6. Continue the pending operation:

   - Merge: `git commit` (use the prepared `MERGE_MSG`).
   - Rebase/cherry-pick: `git rebase --continue` (or `--skip` if the commit became empty) / `git cherry-pick --continue`.
   - Revert: `git revert --continue`.
   - Stash pop / manual: nothing to continue; proceed to commit.

7. If the working tree now has changes relative to HEAD, commit them using the project's commit convention (see `git-commit` skill). If the tree is clean, report that there was nothing to commit.

8. Report: which files conflicted, how each was resolved, and the resulting commit (or "nothing to commit").

## Notes

- Never run `git stash` (push/pop/apply/drop) in a shared workspace; resolve conflicts in place and leave the stash list untouched if dropping is blocked.
- Do not force-resolve hand-written source collisions without user confirmation.
- Prefer the version already in HEAD when the incoming change is a stale duplicate.
