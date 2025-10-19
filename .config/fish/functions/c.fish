#!/usr/bin/env fish
function c --wraps=git --description='Performs a git checkout.'
    git checkout $argv
end
