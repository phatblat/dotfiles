#!/usr/bin/env fish
# When checking out paths from the index, check out stage #3 (theirs) for unmerged paths.
function theirs
    git checkout --theirs $argv; and git add $argv
end
