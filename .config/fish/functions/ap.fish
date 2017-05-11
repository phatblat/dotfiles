# Selectively add some of the modifications in the work tree to the git staging area.
function ap
    git add --patch $argv
end
