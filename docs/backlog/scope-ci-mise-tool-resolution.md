# Scope CI mise tool resolution

Priority: Unprioritized

## Problem

The `Install mise and tools` step in `.github/workflows/check.yml` spends most of its time resolving versions of tools the job never installs. On 2026-08-09 the step took about 32s on a cache hit. Restoring the 122 MB cache took about 1s and `mise install` took the remaining 30s. During that time the log shows GitHub API calls for tools absent from the install list (`zoxide`, `xh`, `yq`, `SwiftFormat`, `awscli`, `dotnet`, `softnet`), five PyPI lookups, and a closing `updating 1 lockfiles` ([debug run 31316113490](https://github.com/phatblat/dotfiles/actions/runs/31316113490)). A cache miss took 37s, so the cache saves about 5s and the rest is resolution.

The cost appears to scale with tools that are configured but not installed: `.config/mise/config.toml` configures about 150, and CI installs a handful. It does not reproduce on a machine with every configured tool installed, where the same command takes 373ms. It is not network time either: the `just` artifact downloads in 308ms and the releases API answers in 799ms.

## Outcome

On a cache hit, the CI mise step no longer resolves versions for tools outside the job's install list. A CI run's debug log confirms it, and the step's duration drops accordingly.

## Notes

- After the 2026-08-09 measurement, `0cd9e9f` added a `MISE_ENABLE_TOOLS` allowlist to the lint job. The test job has none. On [run 41197342294](https://github.com/phatblat/dotfiles/actions/runs/41197342294) (2026-10-31) the step took 163s in lint and 73s in test, with longer `install_args` lists than in August. How much of that is resolution has not been re-measured.
- A local reproduction needs a validated isolation method first. Four trimmed-config attempts all measured about 28s because mise kept loading `~/.config/mise/config.toml`, even with `HOME` pointed at a temp directory and a neutral working directory (`mise config` still listed it). Do not trust a local before/after measurement that has not confirmed which config mise loaded.
- Directions:
  - A CI-scoped mise config listing only the tools the workflow needs. It is a second source of truth, so it wants a parity check or generation step.
  - A `MISE_ENABLE_TOOLS` allowlist for the test job too.
  - Install the full tool set once and rely on the cache.
  - Report it upstream: resolving uninstalled tools during an explicitly scoped `mise install` looks more like a bug than intent.
- Keep `e381211` regardless: letting `jdx/mise-action` run the install is what gets the cache written at all.
- Imported from [#412](https://github.com/phatblat/dotfiles/issues/412).
