#!/usr/bin/env fish
# Push tags to remote.
function pushtags
    git push --tags $argv
end
