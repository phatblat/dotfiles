# Git diff.
function d
    git diff \
        --unified=1 --indent-heuristic --no-prefix --diff-algorithm=patience --word-diff=color \
        $argv
end

