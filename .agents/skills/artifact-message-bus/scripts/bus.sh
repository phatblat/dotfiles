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
  mkdir -p "$r/.bus"/{inbox,claimed,done,quarantine}
  [ -f "$r/.bus/agents.md" ] || printf '# Bus roster\n' > "$r/.bus/agents.md"
  touch "$r/.bus/inbox/.keep" "$r/.bus/claimed/.keep" "$r/.bus/done/.keep" "$r/.bus/quarantine/.keep"
  if ! git -C "$r" diff-index --quiet HEAD -- .bus 2>/dev/null || ! git -C "$r" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$r" add .bus && git -C "$r" commit -q -m "bus: init" && echo "initialized .bus/"
  else
    echo "bus already initialized"
  fi
}

cmd_post() { # post <from> <to> <type> <thread> [subject]  (body on stdin)
  [ $# -ge 4 ] || die "usage: post <from> <to> <type> <thread> [subject] < body"
  local r id f
  r=$(root)
  id=$(msgid)
  local from=$1 to=$2 type=$3 thread=$4 subject=${5:-$4}
  # Validate charset: reject path traversal, embedded newlines, control chars
  case "$from" in *[/$'\n'$'\r'$'\t']* | .* | */.* | *.. | *..*) die "invalid from: $from";; esac
  case "$to" in *[/$'\n'$'\r'$'\t']* | .* | */.* | *.. | *..*) die "invalid to: $to";; esac
  case "$type" in *[$'\n'$'\r'$'\t']* | .* | */* | *.. | *..*) die "invalid type: $type";; esac
  case "$thread" in *[$'\n'$'\r'$'\t']* | .* | */* | *.. | *..*) die "invalid thread: $thread";; esac
  mkdir -p "$r/.bus/inbox/$to"
  f="$r/.bus/inbox/$to/$id.md"
  {
    printf -- '---\nid: %s\nfrom: %s\nto: %s\ntype: %s\n' "$id" "$from" "$to" "$type"
    [ "$type" = request ] && printf 'state: submitted\n'
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
  local r a m src dst claim_sha
  r=$(root)
  a=$1
  m=$2
  src=".bus/inbox/$a/$m.md"
  dst=".bus/claimed/$a/$m.md"
  cd "$r"
  # Refuse dirty trees to avoid data loss
  git diff-index --quiet HEAD -- || die "working tree has uncommitted changes"
  git pull --rebase -q || true
  [ -f "$src" ] || { echo "gone (already claimed?)"; exit 2; }
  mkdir -p ".bus/claimed/$a"
  git mv "$src" "$dst"
  sed -i.bak 's/^state: submitted$/state: working/' "$dst" && rm -f "$dst.bak"
  git add "$dst"
  if sync_push "bus: claim [$m] by $a"; then
    # Verify ownership: ensure we still have the claim commit
    claim_sha=$(git rev-parse HEAD)
    git pull --rebase -q || true
    if git merge-base --is-ancestor "$claim_sha" HEAD && [ -f "$dst" ]; then
      echo "$dst"
    else
      echo "lost claim race (commit rebased away or file removed)"; exit 2
    fi
  else
    # Push failed, abort changes without --hard reset
    git reset -q HEAD
    git checkout -q -- "$dst" "$src" 2>/dev/null || true
    echo "lost claim race"; exit 2
  fi
}

cmd_done() { # done <agent> <msg-id> <completed|failed|abandoned> [reason-or-ref ...]
  [ $# -ge 3 ] || die "usage: done <agent> <msg-id> <state> [reason-or-ref ...]"
  local r a m st
  r=$(root)
  a=$1
  m=$2
  st=$3
  shift 3
  # Validate state enum
  case "$st" in
    completed|failed|abandoned) ;;
    *) die "invalid state: $st (must be completed|failed|abandoned)";;
  esac
  # Require reason/refs for failed
  if [ "$st" = failed ] && [ $# -eq 0 ]; then
    die "state 'failed' requires a reason"
  fi
  local src=".bus/claimed/$a/$m.md" dst=".bus/done/$a/$m.md"
  cd "$r"
  git pull --rebase -q || true
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
  r=$(root)
  ttl=${1:-24}
  cd "$r"
  git pull --rebase -q || true
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
      # Quarantine with agent path preserved, notify sender with state:failed
      dest=".bus/quarantine/$agent/$id.md"
      mkdir -p ".bus/quarantine/$agent"
      orig_from=$(awk -F': ' '/^from:/{print $2; exit}' "$f")
      awk '
        fm_done { print; next }
        /^state: submitted$/ { print "state: failed"; next }
        /^---$/ && NR>1 {
          print "---8<--- result"
          print "state: failed"
          print "by: janitor"
          print "at: " strftime("%Y-%m-%dT%H:%M:%SZ", systime())
          print "reason: recycled 3 times, no agent completed"
          print "---8<---"
          fm_done=1
          print
          next
        }
        { print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    else
      dest=".bus/inbox/$agent/$id.md"
      mkdir -p ".bus/inbox/$agent"
    fi
    git mv "$f" "$dest" 2>/dev/null || { mv "$f" "$dest"; git add "$f" "$dest"; }
    git add "$dest"
    sync_push "bus: recycle [$id] (n=$n)" || true
    echo "recycled $dest"
  done
}

case "${1:-}" in
  init|post|inbox|claim|done|janitor) c=$1; shift; "cmd_$c" "$@";;
  *) die "usage: bus.sh {init|post|inbox|claim|done|janitor} ...";;
esac
