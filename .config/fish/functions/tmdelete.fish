# https://appleinsider.com/articles/21/06/26/how-to-delete-time-machine-local-snapshots-in-macos#how-to-delete-all-time-machine-local-snapshots
function tmdelete \
    --description 'Delete Time Machine stapshot' \
    --argument-names date_time

    if test -z $date_time
        error 'Usage: tmdelete date_time'
        return 1
    end

    sudo tmutil deletelocalsnapshots $date_time
end
