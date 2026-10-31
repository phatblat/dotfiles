# Give the ness crate its own fixture cases

Priority: Unprioritized

## Problem

The ness crate's tests reach outside the crate for their data. `tests/corpus.rs`
loads guard cases from the repository's `.config/ness/cases/` (via
`repo_root()`), and the `real_policy_compiles` unit test reads
`.config/ness/policy.toml` the same way. The crate ships only
`tests/fixtures/policy.toml`, a minimal policy with no cases beside it.

That means the crate cannot be built and tested on its own: `cargo test` in a
checkout that is not this dotfiles repository fails to find its inputs. Clause
4 of [2026-10-17-ness-policy-as-data](../decisions/2026-10-17-ness-policy-as-data.md)
says the crate "keeps a fixture policy and a handful of fixture cases for
engine unit tests"; the cases half was not delivered. It blocks clause 4 of
[2026-10-12-extract-ness-to-its-own-repository](../decisions/2026-10-12-extract-ness-to-its-own-repository.md),
under which the extracted repository tests verdicts with no dependency on this
repository's layout.

## Outcome

`crates/ness` passes `cargo test` from any checkout location with only its
own files: a fixture policy plus a small set of fixture cases under
`tests/fixtures/cases/` that exercise every table of the engine (one deny and
one allow per rule class, the `span` write-target extraction, the
control-plane floor, and a regex runtime error). The repository-level corpus
run (`.config/ness/cases/` against the real `policy.toml`) stays as a
dotfiles test, and `installed_copy_matches_corpus` keeps proving the installed
binary and the applied policy agree.

## Notes

- The engine unit tests in `policy.rs`, `active.rs`, and `policy_cmd.rs`
  already use `tests/fixtures/policy.toml`; only `corpus.rs` and
  `real_policy_compiles` depend on the repository.
- Keep the fixture cases in the same JSON shape as `.config/ness/cases/` so
  `ness policy check` could be pointed at them.
- Raised by the final review of the policy-as-data branch, 2026-10-18.
