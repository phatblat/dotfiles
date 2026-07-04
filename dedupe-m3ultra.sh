#!/usr/bin/env bash
#
# dedupe-m3ultra.sh — Deduplicate /Users/phatblat_m3ultra into /Users/phatblat
#
# Strategy (from analysis 2026-07-03):
#   The 2.5T backup is ~90% Photos data that exists ONLY in the backup, plus
#   ~956G of redundant copies of those same photos, plus reinstallable/superseded
#   junk. Almost nothing genuinely duplicates the current home.
#
#   KEEPER : Photos Library.photoslibrary  (509G, 84,578 originals, Jun 2026, valid DB)
#   REDUNDANT (within backup):
#     - Photos Library.photoslibrary.zip   (495G — a zip of the keeper)
#     - export/                            (461G — flat export of the keeper's originals)
#   REINSTALLABLE / SUPERSEDED:
#     - Backup/Cyberpunk 2077 (80G), Applications (17G), 2ndBrain (4.8G, current is superset),
#       Calibre Library, caches, .zcompdump-*, empty dirs, etc.
#
# Decisions baked in: keeper -> STANDALONE library in ~/Pictures (no iCloud);
#                     export -> ARCHIVE to external drive, THEN delete.
#
# SAFETY:
#   * Dry-run by default. Pass --execute to actually do anything.
#   * Every destructive step asks y/N (unless --yes).
#   * rm only ever runs on paths under the backup root (asserted).
#   * Redundant photo copies are NOT deleted until the keeper library is
#     verified (valid DB) AND relocated into ~/Pictures.
#   * export/ is verified-copied to the archive dest before it is deleted.
#
# Usage:
#   ./dedupe-m3ultra.sh                         # dry-run: print the whole plan
#   ./dedupe-m3ultra.sh --execute phase0 phase1 phase2 phase3
#   ./dedupe-m3ultra.sh --execute --archive-dest /Volumes/Archive phase4
#   ./dedupe-m3ultra.sh --execute                # run all phases in order, with prompts
#
# Phases:
#   phase0  Preserve backup-only config (.aws .kube .claude-accounts .npmrc .cagent .claude.bak .claude/projects)
#   phase1  Verify keeper library (DB integrity)  — then open it in Photos.app yourself
#   phase2  Relocate keeper library -> ~/Pictures  (mv, instant, same volume)
#   phase3  Delete redundant .zip  (495G, instant)  [requires library verified+relocated]
#   phase4  Archive export/ -> --archive-dest, verify, then delete  (461G)
#   phase5  Delete reinstallable/superseded (Cyberpunk, Applications, 2ndBrain, junk)
#   phase6  Stage remaining small files for review, then remove the backup root

set -euo pipefail

# ------------------------------------------------------------------ constants
BACKUP_ROOT="/Users/phatblat_m3ultra"
BACKUP="$BACKUP_ROOT/phatblat"
HOME_DIR="/Users/phatblat"
PICS_BK="$BACKUP/Pictures"
LIB="$PICS_BK/Photos Library.photoslibrary"
ZIP="$PICS_BK/Photos Library.photoslibrary.zip"
EXPORT="$PICS_BK/export"
CONFIG_REVIEW="$HOME_DIR/m3ultra-config-review"
LEFTOVERS="$HOME_DIR/m3ultra-leftovers"

EXECUTE=0
ASSUME_YES=0
ARCHIVE_DEST=""
PHASES=""

# ------------------------------------------------------------------ helpers
c_bold=$'\033[1m'; c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_dim=$'\033[2m'; c_off=$'\033[0m'
info() { printf '%s\n' "$*"; }
head1() { printf '\n%s== %s ==%s\n' "$c_bold" "$*" "$c_off"; }
warn() { printf '%s! %s%s\n' "$c_yel" "$*" "$c_off"; }
ok()   { printf '%s✓ %s%s\n' "$c_grn" "$*" "$c_off"; }
die()  { printf '%s✗ %s%s\n' "$c_red" "$*" "$c_off" >&2; exit 1; }

sizeof() { [ -e "$1" ] && du -sh "$1" 2>/dev/null | cut -f1 || echo "-"; }

# Guard: refuse to rm anything that is not inside the backup root.
assert_under_backup() {
  case "$1" in
    "$BACKUP_ROOT"|"$BACKUP_ROOT"/*) : ;;
    *) die "REFUSING to delete path outside backup root: $1" ;;
  esac
}

# Echo a command; only execute it when --execute is set.
run() {
  printf '%s  $ %s%s\n' "$c_dim" "$*" "$c_off"
  [ "$EXECUTE" = 1 ] && "$@"
  return 0
}

safe_rm() { assert_under_backup "$1"; run rm -rf -- "$1"; }

# Confirm gate. In dry-run, always "yes" (so the full plan prints). In execute,
# actually prompt unless --yes.
confirm() {
  if [ "$EXECUTE" != 1 ]; then printf '%s  [dry-run] would prompt: %s%s\n' "$c_dim" "$1" "$c_off"; return 0; fi
  if [ "$ASSUME_YES" = 1 ]; then return 0; fi
  printf '%s?%s %s [y/N] ' "$c_yel" "$c_off" "$1"
  local ans=""; read -r ans < /dev/tty || ans=""
  case "$ans" in y|Y|yes|YES) return 0 ;; *) info "  skipped."; return 1 ;; esac
}

# Precondition guard. In --execute mode a failed precondition is fatal (die).
# In dry-run it only warns and signals the caller to skip the rest of the phase
# (use as: <test> || guard "message" || return 0), so the whole plan can be
# previewed end-to-end before any earlier phase has actually run.
guard() {
  if [ "$EXECUTE" = 1 ]; then die "$1"; fi
  warn "$1"
  warn "  (preview only — this phase needs an earlier phase to have actually run)"
  return 1
}

# ------------------------------------------------------------------ phases
phase0_preserve_config() {
  head1 "Phase 0 — preserve backup-only config for review"
  info "These exist ONLY in the backup. Copying to $CONFIG_REVIEW for you to merge by hand (never auto-merged)."
  run mkdir -p "$CONFIG_REVIEW"
  local d
  for d in .aws .kube .claude-accounts .npmrc .cagent .claude.bak .claude/projects; do
    if [ -e "$BACKUP/$d" ]; then
      info "  - $d ($(sizeof "$BACKUP/$d"))"
      run rsync -aR "$BACKUP/./$d" "$CONFIG_REVIEW/"
    fi
  done
  ok "Config staged. Review $CONFIG_REVIEW, then these originals get removed with the backup in phase6."
}

phase1_verify_library() {
  head1 "Phase 1 — verify keeper library"
  [ -d "$LIB" ] || die "Keeper library not found: $LIB"
  local db="$LIB/database/Photos.sqlite"
  [ -f "$db" ] || die "Photos.sqlite missing — library may be incomplete."
  info "Library: $LIB  ($(sizeof "$LIB"))"
  if head -c 16 "$db" | grep -q "SQLite format 3"; then ok "Photos.sqlite header valid."; else die "Photos.sqlite header invalid."; fi
  if command -v sqlite3 >/dev/null 2>&1; then
    info "Running read-only quick_check (this only reads, never writes)..."
    local res; res="$(sqlite3 "file:$db?mode=ro" 'PRAGMA quick_check;' 2>/dev/null | head -1 || true)"
    [ "$res" = "ok" ] && ok "quick_check: ok" || warn "quick_check returned: '${res:-<none>}' — inspect before trusting."
  fi
  warn "BEFORE running phase3/phase4, open this library in Photos.app (double-click it) and confirm your"
  warn "photos load. The redundant copies are your only fallback until you've done that."
}

phase2_relocate_library() {
  head1 "Phase 2 — relocate keeper library -> ~/Pictures (standalone)"
  [ -d "$LIB" ] || { warn "Library not in backup (already moved?). Skipping."; return 0; }
  local dest="$HOME_DIR/Pictures/Photos Library.photoslibrary"
  [ -e "$dest" ] && die "Destination already exists: $dest (won't overwrite)."
  info "Same volume -> instant mv. $LIB"
  info "  -> $dest"
  if confirm "Move the 509G library into ~/Pictures now?"; then
    run mv "$LIB" "$dest"
    ok "Moved. Open it in Photos.app; it stays a standalone local library (no iCloud unless you enable it)."
  fi
}

phase3_delete_zip() {
  head1 "Phase 3 — delete redundant .zip (495G, instant reclaim)"
  [ -e "$ZIP" ] || { warn "Zip already gone. Skipping."; return 0; }
  [ -d "$HOME_DIR/Pictures/Photos Library.photoslibrary" ] || guard "Keeper library not yet in ~/Pictures — run phase2 first." || return 0
  info "Redundant: $ZIP ($(sizeof "$ZIP"))  — it is a zip of the library you just relocated."
  if confirm "Confirm you have OPENED the relocated library in Photos.app and it works, and delete the .zip?"; then
    safe_rm "$ZIP"
    ok "Deleted .zip (~495G freed)."
  fi
}

phase4_archive_export() {
  head1 "Phase 4 — archive export/ to external, verify, then delete (461G)"
  [ -e "$EXPORT" ] || { warn "export/ already gone. Skipping."; return 0; }
  info "export/ size: $(sizeof "$EXPORT")"
  [ -d "$HOME_DIR/Pictures/Photos Library.photoslibrary" ] || guard "Keeper library not yet in ~/Pictures — run phase2 first." || return 0
  [ -n "$ARCHIVE_DEST" ] || guard "Pass --archive-dest /Volumes/YourDrive (external drive) for this phase." || return 0
  [ -d "$ARCHIVE_DEST" ] || guard "Archive dest not found: $ARCHIVE_DEST" || return 0

  local need free dest
  need=$(du -sk "$EXPORT" | awk '{print $1*1024}')
  free=$(df -k "$ARCHIVE_DEST" | awk 'NR==2{print $4*1024}')
  info "dest free: $(awk -v b="$free" 'BEGIN{printf "%.0fG", b/1073741824}')"
  [ "$free" -gt "$need" ] || guard "Not enough free space on $ARCHIVE_DEST (need ~$(awk -v b="$need" 'BEGIN{printf "%.0fG",b/1073741824}'))." || return 0

  dest="$ARCHIVE_DEST/m3ultra-photos-export"
  info "Archiving to: $dest"
  if confirm "Copy export/ (461G) to $dest? (long — hours over USB)"; then
    run mkdir -p "$dest"
    run rsync -aH --info=progress2 "$EXPORT/" "$dest/"
    if [ "$EXECUTE" = 1 ]; then
      info "Verifying copy (dry-run rsync — should report no differences)..."
      local diff; diff="$(rsync -aHni "$EXPORT/" "$dest/" | grep -v '^\.d\.\.t' | grep -v 'DS_Store' || true)"
      if [ -z "$diff" ]; then
        ok "Archive verified complete."
        if confirm "Delete the original export/ from the backup now?"; then
          safe_rm "$EXPORT"; ok "Deleted export/ (~461G freed; archived copy at $dest)."
        fi
      else
        warn "Verification found differences — NOT deleting original:"; printf '%s\n' "$diff" | head -20
      fi
    else
      info "  [dry-run] would verify with 'rsync -aHni' then delete original on match."
    fi
  fi
}

phase5_delete_reinstallable() {
  head1 "Phase 5 — delete reinstallable / superseded"
  local item
  # Big, individually confirmed
  for item in "$BACKUP/Backup" "$BACKUP/Applications" "$BACKUP/Applications (Parallels)" "$BACKUP/2ndBrain" "$BACKUP/Calibre Library"; do
    if [ -e "$item" ]; then
      info "  $item  ($(sizeof "$item"))"
      case "$item" in
        *"/Backup") warn "    Cyberpunk 2077 — reinstallable via GOG/Steam. Game SAVES usually live in ~/Library, not here." ;;
        *"/2ndBrain") info "    Current ~/2ndBrain is a strict superset (only diff = Obsidian plugin binaries)." ;;
      esac
      confirm "Delete ${item##*/}?" && safe_rm "$item"
    fi
  done
  # Junk / regenerable — grouped
  info "Junk/regenerable: .zcompdump-*, caches, Samsung, logseq, conductor, nohup.out, gt, gt.bak"
  if confirm "Delete the grouped junk above?"; then
    for item in "$BACKUP"/.zcompdump-* "$BACKUP/caches" "$BACKUP/Samsung" "$BACKUP/logseq" \
                "$BACKUP/conductor" "$BACKUP/nohup.out" "$BACKUP/gt" "$BACKUP/gt.bak"; do
      [ -e "$item" ] && safe_rm "$item"
    done
    ok "Junk removed."
  fi
}

phase6_sweep_and_remove() {
  head1 "Phase 6 — stage remaining small files, then remove backup root"
  [ ! -d "$LIB" ] || guard "Keeper library STILL inside backup — run phase2 before removing the root!" || return 0
  info "What remains in the backup:"
  du -sh "$BACKUP"/* "$BACKUP"/.[!.]* 2>/dev/null | sort -rh | head -40 || true
  info ""
  info "Staging notable small dirs to $LEFTOVERS for review (Desktop, Documents, Downloads, dev)..."
  run mkdir -p "$LEFTOVERS"
  local d
  for d in Desktop Documents Downloads dev; do
    [ -e "$BACKUP/$d" ] && run rsync -a "$BACKUP/$d" "$LEFTOVERS/"
  done
  ok "Staged. Review $LEFTOVERS and $CONFIG_REVIEW."
  info ""
  warn "Final step removes the ENTIRE backup ($(sizeof "$BACKUP_ROOT")). Make sure phases 0-5 are done and reviewed."
  if confirm "Remove $BACKUP_ROOT permanently?"; then
    assert_under_backup "$BACKUP_ROOT"
    run rm -rf -- "$BACKUP_ROOT"
    ok "Backup removed. Disk reclaimed."
  fi
}

# ------------------------------------------------------------------ arg parsing
while [ $# -gt 0 ]; do
  case "$1" in
    --execute) EXECUTE=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --archive-dest) shift; ARCHIVE_DEST="${1:-}" ;;
    --archive-dest=*) ARCHIVE_DEST="${1#*=}" ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    phase[0-6]) PHASES="$PHASES $1" ;;
    *) die "Unknown arg: $1 (use --help)" ;;
  esac
  shift
done

[ -d "$BACKUP" ] || die "Backup not found at $BACKUP — nothing to do."
[ -n "$PHASES" ] || PHASES="phase0 phase1 phase2 phase3 phase4 phase5 phase6"

if [ "$EXECUTE" = 1 ]; then
  printf '%sMODE: EXECUTE%s (destructive steps will run after y/N)\n' "$c_red$c_bold" "$c_off"
else
  printf '%sMODE: DRY-RUN%s (nothing will change; pass --execute to act)\n' "$c_grn$c_bold" "$c_off"
fi

for p in $PHASES; do
  case "$p" in
    phase0) phase0_preserve_config ;;
    phase1) phase1_verify_library ;;
    phase2) phase2_relocate_library ;;
    phase3) phase3_delete_zip ;;
    phase4) phase4_archive_export ;;
    phase5) phase5_delete_reinstallable ;;
    phase6) phase6_sweep_and_remove ;;
  esac
done

head1 "Done"
# NOTE: intentionally not du-ing the whole backup here — on a multi-TB tree that
# takes minutes and would make every run look like it hung. Check size on demand:
info "Tip: check reclaimed space with:  du -sh $BACKUP_ROOT"
