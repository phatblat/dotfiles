
# null
function abort
    git merge --abort 2> /dev/null || git rebase --abort 2> /dev/null || git cherry-pick --abort 2> /dev/null || git am --abort
end
