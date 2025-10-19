#!/usr/bin/env fish
# List dirs
function ldir --wraps ls
    for path in (find . -type d -maxdepth 1)
        # Strip the preceeding './' off the filename.
        set -l dir (string split "/" -- $path)[-1]
        ls -d $dir
    end
end
