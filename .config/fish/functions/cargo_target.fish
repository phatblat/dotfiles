#!/usr/bin/env fish
function cargo_target \
    --description='Spins up a RAM disk for Cargo target output' \
    --argument-names quiet
# argparse 'h/help' 'n/name' -- $argv

    set -l drive_name CargoTarget
    set -l default_size 50
    set -l target_path /Volumes/$drive_name
    set -l icon_file ~/Pictures/Icons/rustacean-flat-happy.webp

    set -l output
    if test -d $target_path
        echo "$drive_name already mounted"
        set output (diskutil list $drive_name)
    else
        set output (ramdisk $default_size $drive_name)
        fileicon set "/Volumes/$drive_name" "$icon_file"
    end

    set --export --global CARGO_TARGET_DIR $target_path

    if test -z "$quiet"
        list $output
    end
end
