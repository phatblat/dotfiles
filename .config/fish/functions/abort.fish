# Aborts an in-progress git merge, rebase, cherry-pick or am (apply mail patch).
function abort
    git merge --abort ^/dev/null
    or git rebase --abort ^/dev/null
    or git cherry-pick --abort ^/dev/null
    or git am --abort ^/dev/null
end
