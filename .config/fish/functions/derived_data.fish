function derived_data \
    --description='Spins up a RAM disk for Xcode DerivedData' \
    --argument-names quiet

    set -l drive_name DerivedData
    set -l target_path /Volumes/$drive_name

    set -l output
    if test -d $target_path
        echo "$drive_name already mounted"
        set output (diskutil list $drive_name)
    else
        set output (ramdisk 10 $drive_name)
    end

    if test -z "$quiet"
        list $output
    end
end
