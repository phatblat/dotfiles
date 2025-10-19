#!/usr/bin/env fish
# Print the first 9 chars of the SHA1 of the HEAD commit.
function shortsha
    git rev-parse --short HEAD $argv
end
