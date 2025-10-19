#!/usr/bin/env fish
function skip \
    --description='Skip the current commit in a git rebase/cherry-pick/am.'

    git rebase --skip 2>/dev/null
    or git cherry-pick --skip 2>/dev/null
    or git am --skip 2>/dev/null
end
