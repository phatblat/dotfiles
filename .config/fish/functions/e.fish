#!/usr/bin/env fish
# Short alias for editing a file. Given no args, the current folder
# will be opened in the default text editor.
function e
    if test -z "$argv"
        edit .
    else
        edit "$argv"
    end
end
