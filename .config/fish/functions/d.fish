function d \
    --description='Git diff'

    # --unified: Context lines
    # --no-prefix: Do not show any source or destination prefix. (e.g. "a/" "b/")
    # --no-indent-heuristic: Disable the default heuristic that shifts diff hunk boundaries to make patches easier to read.
    git diff \
        --unified=1 \
        $argv

        # word diff conflicts with diff-so-fancy
        # --word-diff=color \
        # --word-diff-regex='[^[:space:]]' \
        # --diff-algorithm=default \
        # --no-prefix \
        # --no-indent-heuristic \
        # --ignore-cr-at-eol \
end
