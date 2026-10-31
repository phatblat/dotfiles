# Fix the nixtest smoke test skip guard

Priority: Unprioritized

## Problem

`just test` runs `nixtest: smoke — runs nix-instantiate and exits 0` in `tests/nu-wave1-tools.bats`, and it can fail with:

```text
Command `nix-instantiate` not found
```

The test's skip guard checks `command -v nix-instantiate` in bats' bash. It then runs `nixtest` (`.config/nushell/autoload/nixtest.nu`, which calls `^nix-instantiate`) under `nu --no-config-file`. When the two disagree about whether the executable is available, the test fails instead of skipping.

## Outcome

The smoke test skips when `nix-instantiate` is unavailable to the Nushell process, or invokes it through a path both shells resolve the same way. It never fails with the not-found error above.

## Notes

- Reproduce with `bats -f nixtest tests/nu-wave1-tools.bats` on a machine where bash finds `nix-instantiate`. Where bash does not find it, the test skips and the failure does not reproduce.
- Imported from [#386](https://github.com/phatblat/dotfiles/issues/386).
