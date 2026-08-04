# OMP Agent YAML Formatting — Design Spec

## Goal

Normalize the formatting of `~/.omp/agent/config.yml` without changing any OMP
settings or changing the file's required YAML format.

## Approach

Use the existing pinned Prettier 3.9.6 installation to format this one explicit
YAML path:

```sh
prettier --write ~/.omp/agent/config.yml
```

The file is OMP's global settings file and must remain YAML. TOML is not a
supported format for this path, so no TOML conversion or TOML formatter setup
is included.

## Scope

The change is limited to `~/.omp/agent/config.yml`. Expected formatting changes
include removing trailing whitespace, using normal YAML indentation, and
representing the empty `webSearchOrder` list canonically. Values, keys, and
configuration behavior must remain unchanged.

No repository formatter configuration, editor configuration, tooling version,
or unrelated configuration file changes are part of this work.

## Failure Handling

Prettier parses YAML before it writes. If parsing fails, it must leave the
configuration unmodified and report the parse error. No manual rewrite or
format conversion is a fallback.

## Verification

1. Run `prettier --write ~/.omp/agent/config.yml`.
2. Run `prettier --check ~/.omp/agent/config.yml` to confirm the resulting file
   is valid for Prettier's YAML parser and needs no further formatting.
3. Compare the pre- and post-format parsed YAML mappings to confirm the settings
   structure is unchanged.

## Rollback

Restore the exact pre-format file contents if parsed settings differ or OMP
subsequently reports a configuration-load error.
