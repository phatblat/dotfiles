#!/usr/bin/env fish
function unmount \
    --description='Unmounts a drive' \
    --argument-names drive_path

    if test -z $drive_path
        error 'Usage: unmount drive_path'
        return 1
    else if test ! -d $drive_path
        error "Not found: $drive_path"
        return 2
    end

    hdiutil unmount $drive_path
end
