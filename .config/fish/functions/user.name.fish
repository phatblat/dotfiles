#!/usr/bin/env fish
function user.name \
        --description="Manages the user.name git configuration setting."
    git config user.name $argv
end
