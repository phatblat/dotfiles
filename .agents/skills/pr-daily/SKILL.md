---
name: pr-daily
description: Set up the daily dotfiles branch from the current daily branch, clean up previous daily branches, and ensure a draft PR exists. Use when invoked as `$pr-daily` or when the user asks to start the daily dotfiles workflow.
---

# pr-daily

Set up today's daily branch from the current daily branch, clean up old daily branches, and ensure a draft PR exists.

## Workflow

1. Detect context:

   ```bash
   remote=$(git remote | head -1)
   dow=$(date +%A | tr '[:upper:]' '[:lower:]')
   if [ "$dow" = "saturday" ] || [ "$dow" = "sunday" ]; then today="weekend"; else today="$dow"; fi
   today_date=$(date +%Y-%m-%d)
   default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
   current_branch=$(git branch --show-current)
   source_branch=${current_branch}
   echo "remote=${remote} dow=${dow} today=${today} date=${today_date} default=${default_branch} current=${current_branch} source=${source_branch}"
   ```

2. Prune stale remote-tracking refs:

   ```bash
   git fetch "${remote}" --prune
   ```

3. Check for uncommitted changes. If dirty, show files and ask whether to commit, stash, or abort. Do not silently stash or discard.

4. Clean up previous daily branches named `monday`, `tuesday`, `wednesday`, `thursday`, `friday`, and `weekend`, skipping today's name and `${source_branch}` so the source remains available until today's branch is created:

   - If the branch has a merged PR, delete local branch and remote branch if present.
   - If the PR is open, closed-unmerged, or absent, leave it and report why.

5. Keep `${source_branch}` checked out as the base for today's branch. Do not switch to the default branch.

   - If it is a daily branch, use it as the source.
   - If it is the default branch, use it as the fallback when no daily branch is active.
   - If it is any other branch, ask whether to use it or abort rather than silently inheriting unrelated work.

   When the source differs from today, check whether that exact source branch exists on the remote. Treat the lookup status as a safety boundary:

   - **Status `0`**: Fetch and fast-forward the remote source before branching.
   - **Status `2`**: The remote source is absent; intentionally continue with the local source branch.
   - **Any other status**: Report the lookup failure and stop the workflow before branching. Do not treat network, authentication, or remote errors as a missing branch.

   ```bash
   if test "${source_branch}" != "${today}"; then
     source_remote_status=0
     git ls-remote --exit-code --heads "${remote}" "${source_branch}" >/dev/null 2>&1 || source_remote_status=$?

     case "${source_remote_status}" in
       0)
         git fetch "${remote}" "${source_branch}"
         git merge --ff-only "${remote}/${source_branch}"
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

6. Create or switch to today's branch:

   - Existing local branch: `git checkout "${today}"`
   - Existing remote branch: `git checkout -b "${today}" "${remote}/${today}"`
   - New branch: `git checkout -b "${today}" "${source_branch}"`

   Establish or verify tracking. For new branches, push with:

   ```bash
   git push -u "${remote}" "${today}:${today}"
   ```

7. Ensure a draft PR exists:

   ```bash
   gh pr list --head "${today}" --state open --json number,url --jq '.[0] | "\(.number)|\(.url)"'
   ```

   If no PR exists, compare a newly layered branch with its source. On a same-day rerun, compare with the default branch instead because `${source_branch}` and `${today}` are identical:

   ```bash
   comparison_branch=${default_branch}
   if [ "${source_branch}" != "${today}" ]; then
     comparison_branch=${source_branch}
   fi
   git rev-list --count "${comparison_branch}..${today}"
   ```

   If the count is `0`, create an empty marker commit so today's branch remains distinct after the source PR merges:

   ```bash
   git commit --allow-empty -m "chore: start ${today} ${today_date}"
   git push "${remote}" "${today}:${today}"
   ```

   Then create:

   ```bash
   gh pr create --draft --base "${default_branch}" --assignee @me --title "chore: ${today} ${today_date}" --body "Daily dotfiles branch for ${today}, ${today_date}."
   ```

   The branch inherits `${source_branch}`, while the PR continues to target `${default_branch}`. The PR is cumulative until the source PR merges, then its diff shrinks to the newer changes.

8. Report branch, source branch, PR, pruned refs, cleaned branches, and branches intentionally left alone.
