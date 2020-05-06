function derived_data \
    --description='Spins up a RAM disk for Xcode DerivedData' \
    --argument-names argname

    # if test -z argname
    #     echo 'Usage: derived_data [argname]'
    #     return 1
    # end

    if test -d /Volumes/DerivedData
        diskutil list DerivedData
    else
        ramdisk 10 DerivedData
    end
end
