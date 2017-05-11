# Undoes the last commit but leaves the staging area and working copy intact.
# Good for fixing a typo or any other modification to the commit.
function pop
    git reset --soft HEAD^ $argv
end
