# Prune obsolete remote branches on the given remote.
function prune
    git remote prune $argv
end
