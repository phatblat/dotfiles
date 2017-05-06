
# null
function stsnapshot
    git stash save "snapshot: $(date)" && git stash apply "stash@{0}"
end
