#!/usr/bin/env fish
# Interactive rebase for the last few commits, count specified as 1st arg (default: 10).
function r --argument-names count
    if test -z $count
        set count 10
    end

    toggle_wait on

    git rebase --interactive HEAD~$count

    toggle_wait off
end
