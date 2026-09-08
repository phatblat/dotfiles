#!/usr/bin/env bash
# Decide whether a workflow's expensive steps need to run for this event.
#
# `lint`, `test`, and `harness-parity` are required status checks. A check that
# never runs leaves a pull request stuck on "Expected", so the workflows can no
# longer filter at the `on:` trigger — they always start, and this script tells
# them whether there is anything to do. Path lists live here only.
#
# Writes `relevant=true|false` to $GITHUB_OUTPUT. Fails open: anything other than
# a pull request, or any trouble reading the diff, reports true.
#
# Copyright: Ben Chatelain. MIT
set -euo pipefail

profile="${1:?usage: changed.sh <lint|parity>}"

case "$profile" in
lint)
    # Mirrors what `just lint` (`hk check --all`, steps defined in hk.pkl)
    # actually reads: hk.pkl itself, plus every glob its steps check
    # (.gitignore, .codex/config.toml, .config/mise/config.toml, zsh/nushell
    # autoload functions, bin/, tracked *.yml/*.yaml, and the scripts/tests
    # trees hk's Python/shell steps cover). Narrower than this and a lint
    # failure surfaces on some later unrelated pull request instead of the
    # one that caused it.
    pattern='^(hk\.pkl$|\.config/(home-manager|nushell)/|\.config/zsh/functions/|\.config/mise/config\.toml$|\.codex/config\.toml$|\.gitignore$|bin/|justfile$|scripts/|tests/|\.github/(workflows|scripts)/|.*\.ya?ml$|.*\.jsonc?$)'
    ;;
parity)
    # .agents/skills/** is a generator input (SKILL_SOURCE) and belongs here:
    # editing a shared skill can leave generated adapters stale. So are the
    # sibling scripts/harness_*.py modules: the capability registry, the
    # renderers, and the probe/drift rules all feed docs/agent-harnesses.* and
    # docs/harness/**, so a registry-only change must still run the check.
    pattern='^(\.agents/|\.claude/(commands|hooks|skills)/|\.codex/(agents|hooks|skills)/|\.config/(crush|opencode)/|\.cursor/|\.gemini/|\.grok/|\.pi/|\.omp/|crates/|scripts/agent-harnesses\.py$|scripts/agent_plugins\.py$|scripts/harness_[a-z_]+\.py$|docs/agent-harnesses\.|docs/harness/|\.github/(workflows/agent-harness-parity\.yml|scripts/changed\.sh)$)'
    ;;
*)
    echo "unknown profile: $profile" >&2
    exit 64
    ;;
esac

emit() {
    echo "relevant=$1" >> "${GITHUB_OUTPUT:-/dev/stdout}"
    echo "relevant=$1 (profile: $profile)" >&2
}

if [[ ${GITHUB_EVENT_NAME:-} != "pull_request" ]]; then
    emit true
    exit 0
fi

base="${BASE_SHA:-}"
if [[ -z $base ]] || ! git cat-file -e "${base}^{commit}" 2> /dev/null; then
    echo "base commit unavailable; running everything" >&2
    emit true
    exit 0
fi

# Captured rather than piped into grep. Under `set -o pipefail`, `grep -q` exits
# on its first match and the still-writing `git diff` takes SIGPIPE, which makes
# the pipeline report failure — so a *matching* diff would have taken the else
# branch and reported relevant=false, skipping a required check on exactly the
# large pull requests that most need it.
if ! changed_files="$(git diff --name-only "$base" HEAD)"; then
    echo "diff failed; running everything" >&2
    emit true
    exit 0
fi

if grep -qE "$pattern" <<< "$changed_files"; then
    emit true
else
    emit false
fi
