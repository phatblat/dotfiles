# Revisit ness policy pattern-matching design

## Problem

The rm temp-dir exemption and truncate/shred command-position anchoring in
the ness policy use dense fancy-regex that is hard to audit. Corpus cases
cover documented boundaries, but future edits should add a case for each new
boundary. Consider whether these patterns can be handled more elegantly
(structured parsing instead of regex, or simpler anchored patterns) and add
corpus coverage.

## Outcome

The rm and truncate/shred rules are expressed in a form that is easy to audit
and extend, with a corpus case for each boundary. Either the regex is
simplified and documented per-clause, or the matching moves to structured
command parsing.

## Notes

- The policy file is a protected control-plane file; edits must be made
  directly by a human.
- Origin: PR 549 review thread; GitHub issue 551.
