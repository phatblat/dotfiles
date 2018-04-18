function cont \
        --description='Commit an in-progress git merge or continue a rebase, cherry-pick or am (apply mail patch).'
    if test -e .git/MERGE_HEAD
        echo "File exists"
        git commit ^/dev/null
    else if test -e .git/REBASE_HEAD
        git rebase --continue ^/dev/null
    else if test -e .git/CHERRY_PICK_HEAD
        git cherry-pick --continue $argv
    else
        git am --continue ^/dev/null
    end
end
