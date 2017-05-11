# Displays the name of the remote for the current branch.
function remote-for-current-branch
    set current_branch (git rev-parse --abbrev-ref HEAD)
    config branch.$current_branch.remote
end
