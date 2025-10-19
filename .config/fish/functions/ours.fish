#!/usr/bin/env fish
# When checking out paths from the index, check out stage #2 (ours) for unmerged paths.
function ours
    git checkout --ours $argv; and git add $argv
end
