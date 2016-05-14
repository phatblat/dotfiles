#-------------------------------------------------------------------------------
#
# shell/rsync.zsh
# Regular rsync commands initiated by cron.
#
#-------------------------------------------------------------------------------


source=/Users/phatblat/
destination=/Volumes/ThunderBay/Users/phatblat/

#
# Uses rsync to copy files between two locations
#
# $1 - source
# $2 - destionation
# $3 - dry run (if specified)
#
function sync {
  echo "args: $* ($#)"
  if (( $# < 2 )); then
    echo "Usage: sync source/ destination"
    return 1
  fi

  echo "rsyncing ${source} -> ${destination}"
  mkdir -p "${destination}"

  # Test (-anv)
  # rsync --archive --verbose --dry-run "${source}" "${destination}"

  # Run (-aP)
  rsync --archive --partial --progress "${source}" "${destination}"
}
