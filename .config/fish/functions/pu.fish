# Update Pods without updating repos.
function pu
    pod update --no-repo-update $argv
end
