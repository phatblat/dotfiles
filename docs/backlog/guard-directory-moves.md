# Guard directory moves that replace protected files

Priority: Unprioritized

## Problem

The ness guard tests the path tokens of a mutating command (`rm`, `mv`,
`cp`, `tee`, redirects, …) against `[protected_paths]` and `[control_plane]`.
Those patterns name files, so a command whose arguments name only a parent
directory matches nothing:

```bash
mv ~/.local/state/ness /tmp/aside        # removes applied.json from view
mv /tmp/forged ~/.local/state/ness       # plants a forged applied.json
```

Neither line mentions `applied.json`, so both are allowed. The same holds for
`~/.local/bin` (the guard binary), `~/.config/ness` (the policy), and any
directory above a protected secret. This was already true before
[2026-10-17-ness-policy-as-data](../decisions/2026-10-17-ness-policy-as-data.md)
(the binary and the hook scripts could be replaced the same way), and that
decision only promised the guard's existing strength. But `applied.json` makes
the gap cheaper to exploit: forging it and the policy together, with
`ness policy apply` never run, defeats the human-only apply gate.

## Outcome

A mutating command whose target or source is a directory that contains a
protected or control-plane path is denied the way a direct write to that path
is. `mv`, `cp -r`, `rm -r`, `rsync`, and `ln` on `~/.local/state/ness`,
`~/.config/ness`, `~/.local/bin`, `~/.ssh`, and the parents of every other
protected entry are covered, with corpus cases for each. Ordinary work in
unrelated directories is unchanged.

## Notes

- Possible shapes: a `[protected_dirs]` table of directory patterns matched
  against each path token with a trailing-slash normalization; or, for each
  path token that names an existing directory, test the protected regexes
  against the known protected file names joined under it.
- Renames of ancestors further up (`mv ~/.local ~/x`) are the same problem one
  level higher; decide how far up to go and say so in the decision.
- `ness policy apply` could also verify, before installing, that
  `~/.local/state/ness` and `~/.config/ness` are real directories and not
  symlinks, which closes the planted-symlink variant without a guard change.
- Raised by the final review of the policy-as-data branch, 2026-10-18.
