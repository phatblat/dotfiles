#!/usr/bin/env fish
function pushf --description='Force a git push.'
    push --force $argv
end
