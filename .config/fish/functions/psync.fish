# 
function psync
      if (( $# < 2 )); then
    echo "Usage: sync source_dir/ destination_dir/"
    return 1
  fi

  local source_dir="$1"
  local destination_dir="$2"

  if [[ $3 == "go" ]]; then
    # Output is suppressed when not connected to TTY
    [ -t 0 ] && echo "rsyncing ${source_dir} -> ${destination_dir}"
    mkdir -p "${destination_dir}"
    # Run (-aP)
    rsync --archive --one-file-system --safe-links --partial --delete-after "${source_dir}" "${destination_dir}"
  else
    echo "rsyncing ${source_dir} -> ${destination_dir} (dry run)"
    # Test (-anv)
    rsync --archive --one-file-system --safe-links --verbose --dry-run "${source_dir}" "${destination_dir}"
  fi $argv
end
