#!/usr/bin/env fish
# List symbolic links in the current dir.
function lsym --wraps ls
    for path in (find . -type l -maxdepth 1)
        # Strip the preceeding './' off the link filename.
        set -l symlink (string split "/" -- $path)[-1]
        ls -o $symlink
    end
end
