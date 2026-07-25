# Pup mise Migration — Design Spec

## Goal

Move Pup 1.6.6 from Homebrew to mise while preserving the working binary and
existing Datadog authentication state.

## Approach

Use mise's `github:` backend to install the prebuilt release from
`DataDog/pup`. This matches the repository's existing GitHub-backed tool
configuration and avoids compiling Pup from source.

Add the following pinned entry to `.config/mise/config.toml`:

```toml
"github:DataDog/pup" = "1.6.6"
```

## Migration Sequence

1. Add the mise tool entry and install Pup.
2. Verify that mise resolves Pup from its installation directory and that the
   binary reports version 1.6.6.
3. Remove `datadog-labs/pack/pup` with Homebrew only after the mise verification
   succeeds.
4. Remove the Pup formula and now-unused Datadog tap from `Brewfile`.
5. Remove the obsolete Pup entry from `.config/homebrew/trust.json` and untap
   `datadog-labs/pack`.

The migration does not delete Pup configuration, OAuth sessions, or Keychain
items.

## Failure Handling

If the mise installation or verification fails, leave the Homebrew formula and
declarative Homebrew configuration unchanged. If removal fails after mise has
been verified, keep the mise installation and report the remaining Homebrew
cleanup.

## Verification

- `mise which pup` resolves inside mise's install root.
- `mise exec github:DataDog/pup@1.6.6 -- pup --version` reports `1.6.6`.
- A fresh login shell resolves `pup` through mise and reports `1.6.6`.
- `brew list --formula pup` no longer finds the formula.
- `brew tap` no longer lists `datadog-labs/pack`.
- `just format`, `just lint`, and `just test` pass.

## Rollback

Restore the removed `Brewfile` and trust entries, run
`brew install datadog-labs/pack/pup`, and remove the mise tool entry.
