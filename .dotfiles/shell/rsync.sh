#-------------------------------------------------------------------------------
#
# shell/rsync.zsh
# Regular rsync commands initiated by cron.
#
#-------------------------------------------------------------------------------

#
# Uses rsync to copy files between two locations.
#
# Arguments:
# $1 - source
# $2 - destionation
# $3 - dry run if empty, real if "go" (exactly)
#
function sync {
  # echo "args: $* ($#)"
  if (( $# < 2 )); then
    echo "Usage: sync source/ destination/"
    return 1
  fi

  local source="$1"
  local destination="$2"


  if [ "$3" == "go" ]; then
    echo "rsyncing ${source} -> ${destination}"
    mkdir -p "${destination}"
    # Run (-aP)
    rsync --archive --partial --progress "${source}" "${destination}"
  else
    echo "rsyncing ${source} -> ${destination} (dry run)"
    # Test (-anv)
    rsync --archive --verbose --dry-run "${source}" "${destination}"
  fi
}

# Frequent directories

imac=/Users/phatblat/
external=/Volumes/ThunderBay/Users/phatblat/

# Testing
# sync lib/ tmp/ "go"

# Example use
# sync $imac $external
