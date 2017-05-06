
# null
function remote-for-current-branch
    current_branch=$(git rev-parse --abbrev-ref HEAD) && config branch.${current_branch}.remote
end
