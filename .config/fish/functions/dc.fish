# Diff the git staging area.
function dc
    git diff --cached $argv
end
