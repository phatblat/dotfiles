# Publish the agent safety policy as an adoptable standard

Priority: Unprioritized

## Problem

The ness policy is one person's configuration in one dotfiles repository.
Anyone else who wants the same protections (control-plane files, secret
patterns, destructive-command rules, per-harness approval baselines) has to
read this repository and copy by hand, and there is no way to take the parts
they agree with and fork the rest. A policy shipped as a release asset of the
ness repository was considered in
[2026-10-17-ness-policy-as-data](../decisions/2026-10-17-ness-policy-as-data.md)
and deferred: it would make this machine's policy the one policy, which is
the wrong shape for sharing.

## Outcome

A published policy document (the `policy.toml` schema plus a reference policy)
that another user can adopt as-is, pin by version, or fork and diverge from,
the way a language standard or a lint ruleset is adopted. ness loads it from
the local path it already reads; adoption is a fetch, not a copy-and-edit.
Decentralized and plugin-like: no central registry is required to publish a
variant.

## Notes

- Depends on the policy being data (the decision above) and on ness living in
  its own repository
  ([2026-10-12-extract-ness-to-its-own-repository](../decisions/2026-10-12-extract-ness-to-its-own-repository.md)).
- Likely shape: the ness repository publishes the schema and a reference
  policy; a user's local `policy.toml` names the base it adopts and lists its
  own overrides; `ness policy check` resolves and diffs against the base.
- The local-apply gate stays: adopting a published base is still a human
  `ness policy apply`.
