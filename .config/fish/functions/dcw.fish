# Diff the git staging area using word diff.
function dcw
    git diff --cached --word-diff $argv
end

