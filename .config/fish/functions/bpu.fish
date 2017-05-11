# Update pods without updating repos.
function bpu
    bundle exec "pod update --no-repo-update $argv"
end
