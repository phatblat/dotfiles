---
name: pr-daily
description: Set up the daily dotfiles branch, clean up previous daily branches, and ensure a draft PR exists. Use when invoked as `$pr-daily` or when the user asks to start the daily dotfiles workflow.
---

# pr-daily

Set up today's daily branch, clean up old daily branches, and ensure a draft PR exists.

## Workflow

1. Detect context:

   ```bash
   remote=$(git remote | head -1)
   dow=$(date +%A | tr '[:upper:]' '[:lower:]')
   if [ "$dow" = "saturday" ] || [ "$dow" = "sunday" ]; then today="weekend"; else today="$dow"; fi
   today_date=$(date +%Y-%m-%d)
   default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
   current_branch=$(git branch --show-current)
   echo "remote=${remote} dow=${dow} today=${today} date=${today_date} default=${default_branch} current=${current_branch}"
   ```

2. Prune stale remote-tracking refs:

   ```bash
   git fetch "${remote}" --prune
   ```

3. Check for uncommitted changes. If dirty, show files and ask whether to commit, stash, or abort. Do not silently stash or discard.

4. Clean up previous daily branches named `monday`, `tuesday`, `wednesday`, `thursday`, `friday`, and `weekend`, skipping today's name:

   - If the branch has a merged PR, delete local branch and remote branch if present.
   - If the PR is open, closed-unmerged, or absent, leave it and report why.

5. Switch to default branch and pull latest unless already there:

   ```bash
   git checkout "${default_branch}"
   git pull "${remote}" "${default_branch}"
   ```

6. Create or switch to today's branch:

   - Existing local branch: `git checkout "${today}"`
   - Existing remote branch: `git checkout -b "${today}" "${remote}/${today}"`
   - New branch: `git checkout -b "${today}"`

   Establish or verify tracking. For new branches, push with:

   ```bash
   git push -u "${remote}" "${today}:${today}"
   ```

7. Ensure a draft PR exists:

   ```bash
   gh pr list --head "${today}" --state open --json number,url --jq '.[0] | "\(.number)|\(.url)"'
   ```

   If no PR exists and the branch has no commits ahead of default, create an empty commit:

   ```bash
   git commit --allow-empty -m "chore: start ${today} ${today_date}"
   git push "${remote}" "${today}:${today}"
   ```

   Then create:

   ```bash
   gh pr create --draft --assignee @me --title "chore: ${today} ${today_date}" --body "Daily dotfiles branch for ${today}, ${today_date}."
   ```

8. Report branch, PR, pruned refs, cleaned branches, and branches intentionally left alone.
