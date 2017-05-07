# Delete local branches which have been merged into master.
# http://stackoverflow.com/questions/6127328/how-can-i-delete-all-git-branches-which-have-been-merged#answer-6127884
function bdm
    git branch -d ( \
        git branch --merged \
        | grep -v "^*" \
        | grep -v "master" \
        | tr -d "\n" \
    ) $argv
end
