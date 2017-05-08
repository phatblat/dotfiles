# Review a given commit, default: HEAD.
function review
    git log -p --max-count=1 $argv
end
