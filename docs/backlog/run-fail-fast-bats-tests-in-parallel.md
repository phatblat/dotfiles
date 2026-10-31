# Run fail-fast bats tests in parallel

Priority: Unprioritized

## Problem

`just test abort` runs the whole bats suite serially, so a fail-fast run pays the full serial cost instead of stopping a parallel run at the first failure.

bats can combine `--abort` with `--jobs N`: `bats-exec-suite` then appends `--halt now,fail=1` to the parallel binary's arguments. That flag is GNU `parallel` syntax, and the `test` recipe in `justfile` passes `--parallel-binary-name rush`, which rejects it:

```text
$ bats --abort --jobs 2 --parallel-binary-name rush tests/codex-hooks.bats tests/bak.bats
...
unknown flag: --halt
# bats warning: Executed 0 instead of expected 16 tests
```

The recipe uses `rush` because `/opt/homebrew/bin/parallel` is moreutils' `parallel` (`Brewfile` installs `moreutils`), not GNU parallel, and the `parallel` formula is not installed. So the recipe's `abort)` branch drops `--jobs` and runs serially, with a comment saying why.

## Outcome

`just test abort` runs test files in parallel and stops the suite at the first failure. Alternatively, fail-fast deliberately stays serial and the tradeoff is documented where `just test` is described, not only in the recipe comment.

## Notes

- Install GNU `parallel` (`brew install parallel`, possibly `brew link --overwrite parallel` to take the `/opt/homebrew/bin/parallel` name from moreutils) and use it for `abort` mode. Keep `rush` for the default `parallel` mode, or switch everything if GNU parallel proves reliable.
- Or put a shim named `rush` ahead of the real one that translates `--halt` into rush's own `-e`/`--stop-on-error`. bats' plumbing may not allow this without patching bats.
- bats-core source: `if (( BATS_ABORT_ON_FAILURE )); then parallel_flags+=('--halt' 'now,fail=1'); fi` in `libexec/bats-core/bats-exec-suite`.
- Imported from [#434](https://github.com/phatblat/dotfiles/issues/434).
