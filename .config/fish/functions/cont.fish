# Commit an in-progress git merge or continue a rebase, cherry-pick or am (apply mail patch).
function cont
    if test -e .git/MERGE_HEAD
        echo "File exists"
        git commit ^/dev/null
    end
    or git rebase --continue ^/dev/null
    or git cherry-pick --continue $argv
    or git am --continue ^/dev/null
end
