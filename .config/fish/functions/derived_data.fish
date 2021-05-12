function derived_data \
    --description='Spins up a RAM disk for Xcode DerivedData' \
    --argument-names quiet

    set -l output
    if test -d /Volumes/DerivedData
        set output (diskutil list DerivedData)
    else
        set output (ramdisk 10 DerivedData)
    end

    if test -z "$quiet"
        list $output
    end
end
