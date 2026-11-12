---
name: git-resolve-conflicts
description: Resolve git conflicts and finish the interrupted git operation. Detects whether a rebase, merge, cherry-pick, revert, am, or stash pop stopped on conflicts, resolves and stages every unmerged path, then continues that same operation until it completes. Use as soon as git output shows "CONFLICT", "Unmerged paths", "both modified", "could not apply", "fix conflicts and then run", "rebase in progress", or "You have unmerged paths", or a config or source file fails to parse on a `<<<<<<<` marker; also when invoked as `$git-resolve-conflicts` or asked to resolve conflicts and continue.
---

# git-resolve-conflicts

Finish a git operation that stopped on conflicts: detect which operation is pending, resolve every unmerged path, stage it, and continue the *same* operation until git reports it complete. Then commit any leftover changes. This skill never aborts, stashes, or pushes; a calling workflow such as `git-rebase` may push afterwards.

## 1. Detect the pending operation

Linked worktrees keep their own state directory, so resolve every state path with `git rev-parse --git-path` instead of assuming `.git/`:

```bash
gp() { git rev-parse --git-path "$1"; }
if   [ -d "$(gp rebase-merge)" ]; then op=rebase
elif [ -d "$(gp rebase-apply)" ] && [ -f "$(gp rebase-apply/applying)" ]; then op=am
elif [ -d "$(gp rebase-apply)" ]; then op=rebase
elif [ -f "$(gp MERGE_HEAD)" ]; then op=merge
elif [ -f "$(gp CHERRY_PICK_HEAD)" ]; then op=cherry-pick
elif [ -f "$(gp REVERT_HEAD)" ]; then op=revert
elif [ -n "$(git diff --name-only --diff-filter=U)" ]; then op=unmerged
else op=none
fi
echo "op=$op"
git status --porcelain=v1
```

- `op=none`: no conflict is in progress. Report that and stop.
- `op=unmerged`: unmerged paths with no operation to continue, from a conflicted `git stash pop`/`git stash apply`, `git merge --squash`, or `git checkout -m`. Resolve in place; step 6 has nothing to continue.
- Any other `op` with **no** unmerged paths: continue only if `git status` says all conflicts are fixed. If it says the operation stopped for an `edit`, `break`, or failed `exec`, the user paused it deliberately: report that and stop.
- `op=rebase`: for the report, read the branch being rebased and the progress from `$(gp rebase-merge)/head-name`, `onto`, `msgnum`, and `end` (apply backend: `$(gp rebase-apply)/head-name`, `next`, `last`).

Record the incoming change. Its intent is what you resolve toward:

| op | Incoming change |
| --- | --- |
| rebase | `git log -1 --format='%h %s' REBASE_HEAD` |
| cherry-pick | `git log -1 --format='%h %s' CHERRY_PICK_HEAD` |
| revert | `git log -1 --format='%h %s' REVERT_HEAD` |
| merge | `git log --oneline HEAD..MERGE_HEAD` |
| am | the `Subject:` line of `git am --show-current-patch` |
| unmerged | none |

## 2. Know which side is which

| op | `--ours`, stage 2, `<<<<<<<` side | `--theirs`, stage 3, `>>>>>>>` side |
| --- | --- | --- |
| merge | your current branch | the branch being merged |
| rebase | the upstream you are rebasing onto, plus commits already replayed | your commit being replayed |
| cherry-pick, revert | your current branch | the picked commit, or its revert |
| am | your current branch | the patch |
| stash pop/apply | `HEAD` | the stash |

During a rebase the sides are inverted relative to "mine vs. theirs": `--ours` keeps upstream and `--theirs` keeps your commit. A `|||||||` section (diff3/zdiff3 style) shows the merge base. Inspect any stage with `git show :1:<path>` (base), `git show :2:<path>` (ours), `git show :3:<path>` (theirs).

## 3. List and classify the conflicts

| `git status --porcelain=v1` code | Meaning | Resolve with |
| --- | --- | --- |
| `UU` | both modified | edit or pick a side, then `git add -- <path>` |
| `AA` | both added | as `UU` |
| `UD`, `DU` | modified on one side, deleted on the other | keep: `git add -- <path>`; delete: `git rm -- <path>` |
| `AU`, `UA` | added on one side, conflicting | edit, then `git add -- <path>` |
| `DD` | deleted on both sides | `git rm -- <path>` |

For each path, read what the other side did to it: `git log --oneline -3 HEAD -- <path>`, plus `git log --oneline -3 MERGE_HEAD -- <path>` for a merge.

With `rerere.enabled`, git may already have replayed a recorded resolution. Git's output then says `Resolved '<path>' using previous resolution.` and the file has no markers. Check the replayed content against step 4 before staging it.

## 4. Resolve each path

Apply the first rule that matches:

1. **Generated files** (a "generated" or "do not edit" header, or listed as generator output in the repo's AGENTS.md): never hand-merge. Take the side from the newer generation; during a rebase that is usually the upstream, `git checkout --ours -- <path>`. Note the repo's regenerate command for the report, and run it after the operation finishes. Examples from phatblat/dotfiles: `docs/harness/**`, `docs/agent-harnesses.*`, `.claude/skills/**` and `.agents/harness/**` regenerate with `just harness-generate`; `.config/mise/conf.d/dotfiles.toml` with `just home-spec`; version and drift captures with `just harness-probe`.
2. **Lockfiles**: never hand-merge. Take the side matching the manifest you resolved, then regenerate with the owning tool's lock command (`uv lock`, `bun install`, `npm install --package-lock-only`, `cargo update --workspace`, `mise lock`) and stage the result.
3. **Version pins and dependency bumps**: for each key, keep the highest version from either side. If the `HEAD` side already has the highest version of every key, the incoming bump is obsolete, so resolve to `HEAD` (`git checkout --ours -- <path>` for rebase and cherry-pick). Step 6 then skips the now-empty commit.
4. **Filtered machine-state files** (a `filter=` attribute in `.gitattributes`, such as trust hashes): keep ours; the clean filter re-normalizes the file on `git add`.
5. **Append-only data** not covered by rule 1 (JSONL logs, changelog-style lists): keep both sides' new entries, drop exact duplicates, and keep chronological order.
6. **Deliberate config change** on one side only, where the other side's edit is unrelated in intent: keep the deliberate value.
7. **Stale stash** (`op=unmerged` from a stash whose changes are already in `HEAD`): keep `HEAD` for every path.
8. **Hand-written source** where both sides changed the same logic: combine them only when both intents are clear and independent, such as two additions to one list. Otherwise stop and ask the user, showing base, ours and theirs plus both commits' subjects. Never guess.

For a mixed result, edit the file. Keep the chosen lines and delete every marker line: `<<<<<<<`, `|||||||` together with the base lines after it, `=======`, and `>>>>>>>`. `git checkout --ours -- <path>` and `git checkout --theirs -- <path>` take a whole side. They are path checkouts, so they work even where branch-switching `git checkout` is blocked. `git checkout -m -- <path>` restores the markers if you need to start over.

## 5. Validate and stage

For each resolved path, confirm no markers remain:

```bash
grep -nE '^(<{7}|\|{7}|={7}|>{7})( |$)' -- <path> && echo "markers remain in <path>"
```

Then parse-check it by type, and fix any failure before staging:

| Type | Check |
| --- | --- |
| TOML | `python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' <path>` |
| JSON, JSONL | `jq empty <path>` |
| YAML | `yq '.' <path> >/dev/null` |
| shell | `bash -n <path>` |
| other source | the repo's linter or compiler for that file, when it runs in seconds |

Stage with `git add -- <path>`, or `git rm -- <path>` for a deletion. When every path is staged, both of these must print nothing:

```bash
git diff --name-only --diff-filter=U
git diff --cached --check
```

## 6. Continue the same operation

Check whether the resolution left anything to commit: `git diff --cached --quiet HEAD && echo empty`.

| op | Resolution has changes | Resolution is empty |
| --- | --- | --- |
| rebase | `GIT_EDITOR=true git rebase --continue` | `git rebase --skip` |
| cherry-pick | `GIT_EDITOR=true git cherry-pick --continue` | `git cherry-pick --skip` |
| revert | `GIT_EDITOR=true git revert --continue` | `git revert --skip` |
| am | `git am --continue` | `git am --skip` |
| merge | `git commit --no-edit` | `git commit --no-edit` (the merge commit records the merge) |
| unmerged | nothing to continue | nothing to continue |

`GIT_EDITOR=true` accepts git's prepared message without opening an editor. Record the subject of every skipped commit for the report; its change was already upstream.

If a commit hook rewrites files (a formatter) and fails, stage the rewritten files and run the same continue command again. If a hook rejects the commit for any other reason, stop and report its output.

Then run step 1 again. A multi-commit rebase, cherry-pick or revert can stop on the next commit, so repeat steps 2–6 until `op=none`.

## 7. Commit leftovers

When `op=none`, run `git status --porcelain=v1`. If changes remain (a resolved stash pop, a `--squash` merge, or `checkout -m`), commit them following the `git-commit` skill's conventions. If the tree is clean, there is nothing to commit.

A conflicted `git stash pop` keeps its stash entry. Leave it in `git stash list` and report it.

## 8. Report

- The operation, the branch (`head-name` for a rebase), and the onto or target ref.
- Each conflicted path, with the rule applied and the side kept.
- Commits skipped as empty.
- Follow-ups:
  - regenerate commands from rules 1–2;
  - a kept stash entry;
  - whether the branch now diverges from its upstream (`git status -sb` shows `ahead N, behind M`), so the user needs `git push --force-with-lease`.

## Never

- Abort the operation (`--abort`) unless the user asks.
- Run `git stash` push, pop, apply or drop, `git push`, or `git reset --hard`.
- Take one side across every path at once (`-X ours`, `-X theirs`, `git checkout --ours .`) without applying step 4 to each path.
- Guess at a hand-written source collision.
