#!/usr/bin/env fish
function cmt --description='Commit with message'
    git commit -m $argv
end
