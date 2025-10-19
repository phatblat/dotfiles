#!/usr/bin/env fish
# sha256
function sha256
    if test -z "$argv"
        echo "Usage: sha256 file1 file2..."
        return 1
    end

    shasum --algorithm 256 $argv
end
