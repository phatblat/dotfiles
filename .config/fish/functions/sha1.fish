#!/usr/bin/env fish
function sha1 \
    --description='Displays the SHA1 hash of files'

    if test -z "$argv"
        echo "Usage: sha1 file1 file2..."
        return 1
    end

    shasum --algorithm 1 $argv
end
