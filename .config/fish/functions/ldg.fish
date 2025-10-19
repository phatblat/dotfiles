#!/usr/bin/env fish
# Annotated git reflog.
function ldg
    git log -g $argv
end
