#!/usr/bin/env fish
function derived_data \
    --description='Spins up a RAM disk for Xcode DerivedData' \
    --argument-names quiet

    set -l drive_name DerivedData
    set -l default_size 10
    set -l target_path /Volumes/$drive_name
    set -l icon_file ~/Pictures/Icons/Agua\ Onyx\ Icons/Onyx\ Media\ Drive.png

    set -l output
    if test -d $target_path
        echo "$drive_name already mounted"
        set output (diskutil list $drive_name)
    else
        set output (ramdisk $default_size $drive_name)
        fileicon set "/Volumes/$drive_name" "$icon_file"
    end

    if test -z "$quiet"
        list $output
    end
end
