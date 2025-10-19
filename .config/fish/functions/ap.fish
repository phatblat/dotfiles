#!/usr/bin/env fish
function ap \
    --description='Selectively add some of the modifications in the work tree to the git staging area.'

    toggle_wait on
    git add --patch $argv
    toggle_wait off
end
