# Remove or repair the inert Harness pipelines

Priority: Unprioritized

## Problem

`.harness/` defines a Harness CI pipeline (lint, tests, Nix build) that cannot run. Harness triggers on GitHub webhooks, and the repository has none: `gh api repos/phatblat/dotfiles/hooks` returns an empty list. The same token reports `permissions.admin: true`, so the empty list is real rather than a permissions blind spot. GitHub Actions has done the real work since the pipelines were added in `e84d8e6` (2026-01-24). `AGENTS.md` still lists `.harness/` as "CI pipeline definitions" under Project Structure, although its Testing Guidelines (since `ff7f580`) say it is inert and not a gate.

If revived as-is, its test stage would pass without testing anything. `.harness/ci.yaml` runs:

```bash
if [ -d ~/tests ]; then
  bats ~/tests/
else
  echo "No tests directory found, skipping..."
fi
```

It does this with no `HOME` remap, unlike `.github/workflows/check.yml`, which sets `HOME: ${{ github.workspace }}`. The repo root is `$HOME`, so in a checkout anywhere else `~/tests` does not exist, and the stage prints "skipping" and exits 0. It would also need mise activated and `rush` installed for the parallel runner.

## Outcome

Either `.harness/` is deleted and nothing in the repo describes it as a pipeline, or it runs on a trigger that exists and its test stage fails when a test fails.

## Notes

- Delete: remove the force-tracked files under `.harness/` (the directory itself is ignored by `.gitignore`), both `AGENTS.md` mentions, and the `.harness/*` example in `hk.pkl`'s pre-commit stash comment.
- Repair: add the `HOME` remap, activate mise, install `rush`, and configure the webhook.
- Imported from [#410](https://github.com/phatblat/dotfiles/issues/410).
