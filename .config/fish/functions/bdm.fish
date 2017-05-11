# Delete local branches which have been merged into the current branch, always preserving master.
# http://stackoverflow.com/questions/6127328/how-can-i-delete-all-git-branches-which-have-been-merged#answer-6127884
function bdm
    git branch --merged \
    | egrep -v "(^\*|master)" \
    | xargs git branch -d
end
