---
name: pr-daily
description: Use when invoked as `$pr-daily` or when the user asks to start the daily dotfiles workflow; sets up the daily branch, cleans old ones, ensures a draft PR.
disable-model-invocation: true
---

# pr-daily

Set up today's daily branch from the current daily branch, clean up old daily branches, and ensure a draft PR exists.

## Worktree model

- The **primary checkout** (`~/dev/dotfiles`) always holds the current day's branch. `mise dot` deploys from it, so its HEAD decides what live `$HOME` contains. Switching it is the user's action, never the agent's.
- A **main worktree** (`~/.worktrees/dotfiles/main`) exists only to pull `main`. Never modify it; at most report whether it is behind `origin/main`.
- Other worktrees hold prior-day branches (PR review and resolution) and occasional feature branches. Only daily-branch worktrees are in scope for cleanup; leave every other worktree alone.

The skill may run from any worktree, so always resolve the primary explicitly and never use the cwd's branch as the source. The agent never runs `git checkout`/`git switch` in the primary (the harness blocks it); today's branch is created with `git branch` and the switch is handed to the user.

## Workflow

1. Detect context:

   ```bash
   remote=$(git remote | head -1)
   dow=$(date +%A | tr '[:upper:]' '[:lower:]')
   if [ "$dow" = "saturday" ] || [ "$dow" = "sunday" ]; then today="weekend"; else today="$dow"; fi
   today_date=$(date +%Y-%m-%d)
   default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
   primary=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
   source_branch=$(git -C "${primary}" branch --show-current)
   echo "remote=${remote} dow=${dow} today=${today} date=${today_date} default=${default_branch} primary=${primary} source=${source_branch} cwd_branch=$(git branch --show-current)"
   ```

   `source_branch` is the branch checked out in the primary. The cwd's branch is reported only.

2. Prune stale remote-tracking refs:

   ```bash
   git fetch "${remote}" --prune
   ```

3. Check the primary for uncommitted changes with `git -C "${primary}" status --porcelain`. If dirty, show files and ask whether to commit, stash, or abort. Do not silently stash or discard. Other worktrees' state is not part of this check.

4. Clean up previous daily branches named `monday`, `tuesday`, `wednesday`, `thursday`, `friday`, and `weekend`, skipping today's name and `${source_branch}` so the source remains available until today's branch is created.

   Branch names are reused every week, so one name can have many merged PRs plus a current open one. For each candidate branch `b` that exists locally or on the remote:

   - **Open PR** (`gh pr list --head "$b" --state open`): leave it, report why.
   - **No open PR**: look at the most recent PR only (`gh pr list --head "$b" --state all --limit 1 --json number,state`). If it is not `MERGED` (closed-unmerged or absent), leave it, report why.
   - **Latest PR merged**: also require no unpushed work, `git rev-list --count "${remote}/$b..$b"` is `0` (squash merges make `git branch -d` unreliable, so this check replaces it). If not zero, leave it and report the commits.
   - **Safe to delete**: find any worktree that has `b` checked out via `git worktree list --porcelain`.
     - If one exists, run `wt remove "$b"`. Never pass `--force`; if the worktree is dirty or `wt` refuses, report it and leave the branch.
     - Then `git branch -D "$b"` and, if the remote branch exists, `git push "${remote}" --delete "$b"`.

   Never remove the main worktree or any worktree whose branch is not a daily branch.

5. Sync the source. `${source_branch}` stays checked out in the primary as the base for today's branch. Do not switch the primary to the default branch.

   - If it is a daily branch, use it as the source.
   - If it is the default branch, use it as the fallback when no daily branch is active.
   - If it is any other branch, ask whether to use it or abort rather than silently inheriting unrelated work.

   When the source differs from today, check whether that exact source branch exists on the remote. Treat the lookup status as a safety boundary:

   - **Status `0`**: Fetch and fast-forward the remote source before branching.
   - **Status `2`**: The remote source is absent; intentionally continue with the local source branch.
   - **Any other status**: Report the lookup failure and stop the workflow before branching. Do not treat network, authentication, or remote errors as a missing branch.

   The fast-forward runs in the primary, the worktree that owns the source branch, so the ref and its working tree move together:

   ```bash
   if test "${source_branch}" != "${today}"; then
     source_remote_status=0
     git ls-remote --exit-code --heads "${remote}" "${source_branch}" >/dev/null 2>&1 || source_remote_status=$?

     case "${source_remote_status}" in
       0)
         git fetch "${remote}" "${source_branch}"
         git -C "${primary}" merge --ff-only "${remote}/${source_branch}"
         ;;
       2)
         echo "Source branch '${source_branch}' is absent from '${remote}'; continuing with the local source branch."
         ;;
       *)
         echo "Failed to inspect source branch '${source_branch}' on '${remote}' (git ls-remote status ${source_remote_status}); stopping before branching." >&2
         exit "${source_remote_status}"
         ;;
     esac
   fi
   ```

   If the fast-forward fails because the local and remote source branches diverged, ask how to proceed rather than merging, rebasing, or force-pushing automatically.

6. Create today's branch without checking it out:

   - Local `${today}` exists: nothing to create.
   - Only `${remote}/${today}` exists: `git branch --track "${today}" "${remote}/${today}"`
   - Neither exists: `git branch "${today}" "${source_branch}"`

   If `${today}` is already checked out in a worktree other than the primary, report that and stop; do not move it.

   Establish or verify tracking. For new branches, push with:

   ```bash
   git push -u "${remote}" "${today}:${today}"
   ```

7. Ensure a draft PR exists:

   ```bash
   gh pr list --head "${today}" --state open --json number,url --jq '.[0] | "\(.number)|\(.url)"'
   ```

   If no PR exists, compare a newly layered branch with its source. On a same-day rerun, compare with the remote default branch instead because `${source_branch}` and `${today}` are identical. Use `${remote}/${default_branch}`, not the local `${default_branch}`: local `main` lives in the main worktree and is only as fresh as the last manual pull.

   ```bash
   comparison_branch=${remote}/${default_branch}
   if [ "${source_branch}" != "${today}" ]; then
     comparison_branch=${source_branch}
   fi
   git rev-list --count "${comparison_branch}..${today}"
   ```

   If the count is `0`, create an empty marker commit so today's branch remains distinct after the source PR merges. Use plumbing so no checkout is needed; include the running harness's `Co-Authored-By` trailer per the shared commit-attribution rule:

   ```bash
   sha=$(git commit-tree "${today}^{tree}" -p "${today}" -m "chore: start ${today} ${today_date}" -m "<harness Co-Authored-By trailer>")
   git update-ref "refs/heads/${today}" "${sha}"
   git push "${remote}" "${today}:${today}"
   ```

   Then create the PR. `--head` is required because the branch is not checked out:

   ```bash
   gh pr create --draft --base "${default_branch}" --head "${today}" --assignee @me --title "chore: ${today} ${today_date}" --body "Daily dotfiles branch for ${today}, ${today_date}."
   ```

   The branch inherits `${source_branch}`, while the PR continues to target `${default_branch}`. The PR is cumulative until the source PR merges, then its diff shrinks to the newer changes.

8. Hand off the switch. If `${source_branch}` differs from `${today}`, the primary is still on the old branch. Print this single line for the user to run in the primary (the post-checkout hook re-runs `mise dot apply`):

   ```nu
   git -C ~/dev/dotfiles switch weekend
   ```

   (Substitute `${today}`.) Do not run it. Once the user switches, `${source_branch}` is free, so `wt switch "${source_branch}"` can turn it into a review worktree for its PR.

9. Report branch, source branch, PR, pruned refs, cleaned branches (and removed worktrees), branches and worktrees intentionally left alone, whether `${primary}` still needs the switch, and, read-only, whether the main worktree is behind `${remote}/${default_branch}` (`git -C ~/.worktrees/dotfiles/main rev-list --count HEAD..${remote}/${default_branch}`).
