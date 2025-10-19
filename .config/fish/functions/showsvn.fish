#!/usr/bin/env fish
# Show .svn directories in the current directory tree.
function showsvn
    find . -type d -name .svn $argv
end
