#!/usr/bin/env fish
function unshallow --description='Converts a shallow git repo to full'
    git fetch --unshallow $argv
end
