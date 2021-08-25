function abort \
    --description='Aborts an in-progress git merge, rebase, cherry-pick or am (apply mail patch).'

    git merge --abort 2>/dev/null
    or git rebase --abort 2>/dev/null
    or git cherry-pick --abort 2>/dev/null
    or git am --abort 2>/dev/null
end
