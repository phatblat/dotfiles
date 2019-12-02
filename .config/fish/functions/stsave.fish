# Save a git stash.
function stsave
    git stash save --include-untracked $argv
end
