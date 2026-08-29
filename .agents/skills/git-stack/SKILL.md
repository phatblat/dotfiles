---
name: git-stack
description: Stack an existing or new git branch on top of another branch, restacking it in a git worktree when needed, then align the GitHub PR bases and stack metadata with `gh stack`. Use when invoked as `$git-stack` or when the user asks to stack or restack a branch or PR onto another branch.
---

# git-stack

Stack `<branch>` onto `<base-branch>` (or restack it onto its current base) in a dedicated worktree, then align GitHub PR bases and the `gh stack` object with the resulting local chain.

## Workflow

1. Parse arguments (drop a bare literal `onto` token):

   | Tokens | Meaning |
   | --- | --- |
   | 0 | `subject` = current branch; `base` resolved in step 2 (restack mode) |
   | 1 | `base` = token; `subject` = current branch |
   | 2 | `subject` = token 1; `base` = token 2 |
   | 3+ | Stop: usage is `stack [<branch>] [<base-branch>]` |

   Stop if `subject` equals `base`.

2. Resolve repo, remote, trunk, and (restack mode) the base:

   ```bash
   repo_root=$(git rev-parse --path-format=absolute --git-common-dir); repo_root=${repo_root%/.git}
   current=$(git branch --show-current)
   remote=$(git config --get "branch.${subject}.remote" || true)
   [ -n "$remote" ] || { mapfile -t remotes < <(git remote); [ "${#remotes[@]}" -eq 1 ] && remote="${remotes[0]}"; }
   [ -n "$remote" ] || { git remote | grep -qx origin && remote=origin; }
   trunk=$(git symbolic-ref "refs/remotes/${remote}/HEAD" 2>/dev/null | sed "s|refs/remotes/${remote}/||")
   [ -n "$trunk" ] || trunk=$(git config init.defaultBranch || echo main)
   git fetch --prune "$remote"
   ```

   Stop if `remote` is still empty and report the candidate remotes. Never hard-code `origin` — the repo's remote may be named anything.

   Restack mode (0 tokens) resolves `base` as the first hit of:

   ```bash
   base=$(gh pr view "$subject" --json baseRefName -q .baseRefName 2>/dev/null)
   [ -n "$base" ] || base=$( (cd "$repo_root" && gh stack view --json 2>/dev/null) | jq -r --arg s "$subject" '
     .branches | to_entries | map(select(.value.name == $s))[0].key as $i
     | if $i == null or $i == 0 then empty else .[$i-1].value.name end')
   ```

   Stop with the usage line if both are empty. Stop if `base` resolves to neither `refs/heads/$base` nor `refs/remotes/$remote/$base`.

3. Pick the working checkout — prefer the worktree that already holds `subject` so a branch checked out elsewhere is never rewritten from the wrong worktree:

   ```bash
   work_dir=$(git worktree list --porcelain | awk -v b="refs/heads/$subject" '
     /^worktree /{ wt=$2 } /^branch /{ if ($2 == b) print wt }')
   ```

   - `work_dir` non-empty → use it; if `git -C "$work_dir" status --porcelain=v1` is non-empty, stop and tell the user to commit or stash there first.
   - `work_dir` empty and `repo_root` is `$HOME` (dotfiles repo) → do **not** create a worktree; `git-worktrees` forbids implicit dotfiles worktrees. If `subject` is the current branch and the tree is clean, set `work_dir="$repo_root"`; otherwise stop and tell the user to run `wt --dotfiles "$subject"` first.
   - Otherwise create one under the `git-worktrees` convention:

     ```bash
     path_key=${repo_root#"$HOME"/}; path_key=${path_key//\//-}
     work_dir="$HOME/.worktrees/${path_key}/${subject}"
     if git show-ref --quiet "refs/heads/${subject}"; then
       git worktree add "$work_dir" "$subject"
     elif git show-ref --quiet "refs/remotes/${remote}/${subject}"; then
       git worktree add --track -b "$subject" "$work_dir" "${remote}/${subject}"
     else                                                        # new-branch mode
       git worktree add "$work_dir" -b "$subject" --no-track "${remote}/${base}"
       git -C "$work_dir" push -u "$remote" "${subject}:${subject}"
       git -C "$work_dir" branch -vv
     fi
     ```

     `--no-track` is mandatory here: a branch cut from a remote base must not inherit the base's upstream. Report the `branch -vv` line as proof it tracks `$remote/$subject`.

   New-branch mode has no commits to replay: report the ready worktree and stop, unless the branch already has commits, in which case continue at step 7 to open its PR.

4. Create a backup (existing-branch mode only):

   ```bash
   git -C "$work_dir" branch "${subject}.bak" "$subject"
   ```

   If `${subject}.bak` already exists, ask whether to overwrite (`git branch -f`) or abort. Keep the backup after success.

5. Restack locally — `--onto` replays exactly the commits unique to `subject`, correct whether it was cut from trunk or an older `base` tip; never plain `git rebase <base>` here:

   ```bash
   base_ref="${remote}/${base}"; git show-ref --quiet "refs/remotes/${base_ref}" || base_ref="$base"
   if git -C "$work_dir" merge-base --is-ancestor "$base_ref" "$subject"; then
     echo "already stacked on ${base}; nothing to replay"
   else
     fork=$(git -C "$work_dir" merge-base "$subject" "$base_ref")
     git -C "$work_dir" rebase --onto "$base_ref" "$fork" "$subject"
   fi
   ```

   (equivalent to `git rebase --onto <base_ref> <merge-base> <subject>`, run with `-C "$work_dir"`.)

   On conflict, follow `git-rebase`'s conflict handler: recorded `rerere` resolution as-is; clean-filtered machine state → `--ours`; version bumps → the higher version; deliberate config updates → `--theirs`; generated artifacts → regenerate. Stage each fix, verify no conflict markers remain, then `GIT_EDITOR=true git -C "$work_dir" rebase --continue` (or `--skip` if the commit went empty). Pause only for genuine semantic collisions in hand-written source. Rollback: `git -C "$work_dir" reset --hard "${subject}.bak"`.

6. Push the subject — before any `gh stack` call, since `gh stack link` pushes without `--force-with-lease`:

   ```bash
   git -C "$work_dir" push --force-with-lease -u "$remote" "${subject}:${subject}"
   git -C "$work_dir" branch --set-upstream-to="${remote}/${subject}" "$subject"
   git -C "$work_dir" branch -vv | grep '^\*'
   ```

   The tracking line must show `[${remote}/${subject}]`; fix it before continuing if it shows the base branch instead.

7. Build the stack chain bottom→top (trunk excluded), capped at 10 hops against a cycle:

   ```bash
   chain=("$subject"); b="$base"; hops=0
   while [ "$b" != "$trunk" ] && [ "$hops" -lt 10 ]; do
     chain=("$b" "${chain[@]}")
     parent=$(gh pr view "$b" --json baseRefName -q .baseRefName 2>/dev/null) || parent=""
     [ -n "$parent" ] || break            # no PR for $b: treat it as the bottom of the stack
     b="$parent"; hops=$((hops + 1))
   done
   ```

8. Ensure every chain member has an open PR based on its parent (previous chain entry, or `$trunk` for the first):

   ```bash
   gh pr view "$member" --json number,state,baseRefName
   ```

   - No PR, or no open PR → invoke `pr-create` for that branch so the repo's title, body, label, draft, and `@me` assignment conventions (`pr-style`) apply, then retarget: `gh pr edit "$number" --base "$parent"`. Never hand-roll `gh pr create` or let `link` auto-create the PR here — both bypass `pr-style`.
   - Open PR whose base differs from `parent` → `gh pr edit "$number" --base "$parent"`.
   - Open PR already based on `parent` → leave it.

9. Align the GitHub stack:

   ```bash
   if [ "${#chain[@]}" -ge 2 ]; then
     (cd "$work_dir" && gh stack link --remote "$remote" --base "$trunk" "${chain[@]}")
   fi
   ```

   A single-member chain (`base` is `trunk`) has no GitHub stack to create — skip `link` and say so; step 8 already put that PR's base on `$trunk`. Always pass `--remote` and `--base` explicitly. Never pass `--open`: new PRs stay drafts.

10. Add local stack tracking, best effort:

    ```bash
    if ! (cd "$work_dir" && gh stack view --json >/dev/null 2>&1) && [ "${#chain[@]}" -ge 2 ]; then
      (cd "$work_dir" && gh stack init --base "$trunk" "${chain[@]}") || echo "local stack tracking unavailable"
    fi
    ```

    A non-zero exit is not a workflow failure — the GitHub metadata from step 9 is already correct; report "local tracking unavailable" and continue. If `gh stack view --json` already succeeds but lists a different branch set, skip `init` and report the mismatch instead of guessing.

11. Report children that now need restacking:

    ```bash
    gh pr list --state open --json number,headRefName,baseRefName \
      --jq ".[] | select(.baseRefName == \"$subject\") | .headRefName"
    ```

    For each child, print the follow-up stack command with `$subject` as its new base. Leaving children based on a rewritten branch silently is the main failure mode of manual stacking.

12. Report:

    ```text
    Stacked <subject> onto <base>.
      Worktree:     <work_dir>
      Chain:        <trunk> → <b1> → … → <subject>
      PRs:          #<n1> (base <trunk>) → … → #<nk> (base <base>)
      GitHub stack: linked | single PR, no stack | local tracking unavailable
      Tracking:     <remote>/<subject>
      Backup:       <subject>.bak  (kept — git branch -D <subject>.bak)
      Children to restack: stack <child> <subject>   (or "none")
    ```

## Never

- Never run bare `gh stack view` — always use `gh stack view --json`; bare `view` opens an interactive TUI.
- Never run the `modify` subcommand, or bare `switch`/`checkout` without a branch argument — both are interactive-only.
- Never run the `submit` subcommand — it auto-generates PR titles/bodies, conflicting with this repo's `pr-style` conventions.
- Never run `unstack [<stack-number>] [--local]` unless the user explicitly asks — it deletes the GitHub stack.
- Never rewrite a branch from a worktree that does not have it checked out.
- Never create a dotfiles worktree implicitly.
</content>
<parameter name="i">Write shared git-stack skill