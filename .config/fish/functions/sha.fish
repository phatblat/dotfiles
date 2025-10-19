#!/usr/bin/env fish
# Print the SHA1 of the HEAD commit.
function sha
    git rev-parse HEAD $argv
end
