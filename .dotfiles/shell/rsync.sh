#!/bin/bash -ex
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
# $1 - source_dir
# $2 - destination_dir
# $3 - dry run if empty, real if "go" (exactly)
#
function sync {
  echo "args: $* ($#)"
  if (( $# < 2 )); then
    echo "Usage: sync source_dir/ destination_dir/"
    return 1
  fi

  local source_dir="$1"
  local destination_dir="$2"

  if [[ $3 == "go" ]]; then
    echo "rsyncing ${source_dir} -> ${destination_dir}"
    mkdir -p "${destination_dir}"
    # Run (-aP)
    rsync --archive --partial --progress "${source_dir}" "${destination_dir}"
  else
    echo "rsyncing ${source_dir} -> ${destination_dir} (dry run)"
    # Test (-anv)
    rsync --archive --verbose --dry-run "${source_dir}" "${destination_dir}"
  fi
}

# Frequent directories

phatblat_imac=/Users/phatblat/
phatblat_external=/Volumes/ThunderBay/Users/phatblat/

# Testing
# sync lib/ tmp/

# Example use
# time sync $phatblat_imac $phatblat_external go
# time sync $phatblat_external $phatblat_imac go
