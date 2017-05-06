# 
function continue
    if [[ -f .git/MERGE_HEAD ]]; then git commit; fi 2> /dev/null || git rebase --continue 2> /dev/null || git cherry-pick --continue $argv
end

