#!/usr/bin/env fish
# Prints the full SHA1 hash of the current HEAD commit.
function headsha
    git rev-parse HEAD
end
