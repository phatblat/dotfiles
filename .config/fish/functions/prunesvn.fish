#!/usr/bin/env fish
# Delete the .svn directories from a directory heirarchy.
function prunesvn
    find . -type d -name .svn -exec rm -rf {} \;
end
