# Skip the current commit in a git rebase.
function skip
    git rebase --skip $argv
end
