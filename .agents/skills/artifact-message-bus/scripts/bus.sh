#!/usr/bin/env bash
# bus.sh — artifact message bus helper (file-mailbox backend)
# Subcommands: init | post | inbox | claim | done | janitor
# Requires: bash, git. Run from anywhere inside the bus repo.
set -euo pipefail

die() { echo "bus: $*" >&2; exit 1; }
root() { git rev-parse --show-toplevel 2>/dev/null || die "not in a git repo"; }
msgid() { printf '%s-%04x' "$(date -u +%Y%m%dT%H%M%SZ)" "$((RANDOM % 65536 | RANDOM % 2 << 15))"; }

sync_push() { # commit staged changes with $1 message, push with one rebase retry
  git commit -q -m "$1"
  git push -q 2>/dev/null && return 0
  git pull --rebase -q || { git rebase --abort >/dev/null 2>&1 || true; return 1; }
  git push -q
}

cmd_init() {
  local r
  r=$(root)
  if ! git -C "$r" diff-index --quiet HEAD -- .bus 2>/dev/null || ! git -C "$r" rev-parse --verify HEAD >/dev/null 2>&1; then
    mkdir -p "$r/.bus"/{inbox,claimed,done,quarantine}
    [ -f "$r/.bus/agents.md" ] || printf '# Bus roster\n' > "$r/.bus/agents.md"
    touch "$r/.bus/inbox/.keep" "$r/.bus/claimed/.keep" "$r/.bus/done/.keep" "$r/.bus/quarantine/.keep"
    git -C "$r" add .bus && git -C "$r" commit -q -m "bus: init" && echo "initialized .bus/"
  else
    echo "bus already initialized"
  fi
}

cmd_post() { # post <from> <to> <type> <thread> [subject] [state]  (body on stdin)
  [ $# -ge 4 ] || die "usage: post <from> <to> <type> <thread> [subject] < body"
  local r id f
  r=$(root)
  id=$(msgid)
  local from=$1 to=$2 type=$3 thread=$4 subject=${5:-$4} state=${6:-}
  # Validate charset: reject path traversal, embedded newlines, control chars.
  # from/to use <crew>/<agent> addressing so a single '/' is expected and
  # allowed; type/thread are bare slugs and never contain one.
  case "$from" in *[$'\n'$'\r'$'\t']* | .* | */.* | *.. | *..* | //*) die "invalid from: $from";; esac
  case "$to" in *[$'\n'$'\r'$'\t']* | .* | */.* | *.. | *..* | //*) die "invalid to: $to";; esac
  case "$type" in *[$'\n'$'\r'$'\t']* | .* | */* | *.. | *..*) die "invalid type: $type";; esac
  case "$thread" in *[$'\n'$'\r'$'\t']* | .* | */* | *.. | *..*) die "invalid thread: $thread";; esac
  mkdir -p "$r/.bus/inbox/$to"
  f="$r/.bus/inbox/$to/$id.md"
  {
    printf -- '---\nid: %s\nfrom: %s\nto: %s\ntype: %s\n' "$id" "$from" "$to" "$type"
    if [ "$type" = request ]; then
      printf 'state: submitted\n'
    elif [ -n "$state" ]; then
      printf 'state: %s\n' "$state"
    fi
    printf 'thread: %s\nreply_to: null\nrefs: []\ndeadline: null\n---\n' "$thread"
    cat
  } > "$f"
  git -C "$r" add "$f"
  ( cd "$r" && sync_push "bus: $to ← $from: $subject [$id]" ) || die "push failed"
  echo "$id"
}

cmd_inbox() { # inbox <agent>
  [ $# -eq 1 ] || die "usage: inbox <agent>"
  local r
  r=$(root)
  git -C "$r" pull --rebase -q || true
  ls -1 "$r/.bus/inbox/$1" 2>/dev/null | grep -v '^\.keep$' || true
}

cmd_claim() { # claim <agent> <msg-id>   exit 0 = yours, exit 2 = lost race
  [ $# -eq 2 ] || die "usage: claim <agent> <msg-id>"
  local r a m src dst
  r=$(root); a=$1; m=$2
  src=".bus/inbox/$a/$m.md" dst=".bus/claimed/$a/$m.md"
  cd "$r"
  git diff-index --quiet HEAD -- || die "working tree has uncommitted changes; commit or stash before claiming"
  git pull --rebase -q || true
  [ -f "$src" ] || { echo "gone (already claimed?)"; exit 2; }
  mkdir -p ".bus/claimed/$a"
  git mv "$src" "$dst"
  # A per-invocation nonce guarantees this commit's content is never
  # byte-identical to a concurrent same-agent claim, so a real race always
  # produces a genuine rebase conflict instead of silently deduping via
  # git's patch-id matching (which would let both callers believe they won).
  local nonce
  nonce="$$-$RANDOM-$(date -u +%s)"
  awk -v claimant="${a}-${nonce}" '
    /^state: submitted$/ { print "state: working"; print "claimant: " claimant; next }
    { print }
  ' "$dst" > "$dst.tmp" && mv "$dst.tmp" "$dst"
  git add "$dst"
  local before
  before=$(git rev-parse HEAD)
  if sync_push "bus: claim [$m] by $a"; then
    grep -qx "claimant: ${a}-${nonce}" "$dst" || {
      git reset -q --hard "$before"
      echo "lost claim race"; exit 2
    }
    echo "$dst"
  else
    # Scope recovery to the claim commit only; never wipe unrelated local state.
    git reset -q --hard "$before"
    echo "lost claim race"; exit 2
  fi
}

cmd_done() { # done <agent> <msg-id> <completed|failed|abandoned> [ref ...]
  [ $# -ge 3 ] || die "usage: done <agent> <msg-id> <completed|failed|abandoned> [ref ...]"
  local r a m st
  r=$(root); a=$1; m=$2; st=$3; shift 3
  case "$st" in
    completed|failed|abandoned) ;;
    *) die "state must be one of completed|failed|abandoned, got: $st" ;;
  esac
  [ "$st" = failed ] && [ $# -eq 0 ] && die "failed requires a reason (pass one as a trailing ref/reason argument)"
  local src=".bus/claimed/$a/$m.md" dst=".bus/done/$a/$m.md"
  cd "$r"; git pull --rebase -q || true
  [ -f "$src" ] || die "no claimed message $m for $a"
  mkdir -p ".bus/done/$a"
  {
    printf -- '\n---8<--- result\nstate: %s\nby: %s\nat: %s\nrefs:\n' \
      "$st" "$a" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    for ref in "$@"; do printf -- '  - %s\n' "$ref"; done
    printf -- '---8<---\n'
  } >> "$src"
  git mv "$src" "$dst"; git add "$dst"
  sync_push "bus: $st [$m] by $a" || die "push failed"
}

cmd_janitor() { # janitor [ttl-hours]   recycle stale claims (quarantine at 3)
  local r ttl cutoff f
  r=$(root); ttl=${1:-24}
  cd "$r"; git pull --rebase -q || true
  # ids are YYYYMMDDTHHMMSSZ-<hex>: lexical compare against a cutoff id works
  cutoff=$(date -u -d "-${ttl} hours" +%Y%m%dT%H%M%SZ 2>/dev/null \
        || date -u -v-"${ttl}"H +%Y%m%dT%H%M%SZ)   # GNU then BSD date
  find .bus/claimed -type f -name '*.md' | while read -r f; do
    grep -q '^state: input-required$' "$f" && continue
    local id agent n dest orig_from
    id=$(basename "$f" .md)
    [ "${id%%-*}" \< "$cutoff" ] || continue
    agent=${f#.bus/claimed/}; agent=${agent%/"$id".md}   # keeps crew/agent nesting
    n=$(awk -F': ' '/^recycled:/{print $2; found=1} END{if(!found)print 0}' "$f")
    n=$((n + 1))
    awk -v n="$n" '
      fm_done { print; next }
      /^state: working$/ { print "state: submitted"; next }
      /^recycled:/ { print "recycled: " n; seen=1; next }
      /^---$/ && NR>1 { if (!seen) print "recycled: " n; fm_done=1; print; next }
      { print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    if [ "$n" -ge 3 ]; then
      # Quarantine with agent path preserved (avoids cross-agent id collisions).
      dest=".bus/quarantine/$agent/$id.md"; mkdir -p ".bus/quarantine/$agent"
      orig_from=$(awk -F': ' '/^from:/{print $2; exit}' "$f")
      awk -v at="$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
        fm_done { print; next }
        /^state: submitted$/ { print "state: failed"; next }
        /^---$/ && NR>1 {
          print "---8<--- result"
          print "state: failed"
          print "by: janitor"
          print "at: " at
          print "reason: recycled 3 times, no agent completed"
          print "---8<---"
          fm_done=1
          print
          next
        }
        { print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    else
      dest=".bus/inbox/$agent/$id.md"; mkdir -p ".bus/inbox/$agent"
    fi
    git mv "$f" "$dest" 2>/dev/null || { mv "$f" "$dest"; git add "$f" "$dest"; }
    git add "$dest"
    sync_push "bus: recycle [$id] (n=$n)" || true
    echo "recycled $dest"
    if [ "$n" -ge 3 ] && [ -n "${orig_from:-}" ]; then
      # Notify the original sender, per protocol.md's recovery contract, instead
      # of leaving them to discover the quarantined file by manual audit.
      printf 'Message %s quarantined after %s failed claim attempts (last claimant: %s).\n' "$id" "$n" "$agent" \
        | cmd_post "bus-janitor" "$orig_from" report "$id" "quarantined: $id" failed || true
    fi
  done
}

case "${1:-}" in
  init|post|inbox|claim|done|janitor) c=$1; shift; "cmd_$c" "$@";;
  *) die "usage: bus.sh {init|post|inbox|claim|done|janitor} ...";;
esac
