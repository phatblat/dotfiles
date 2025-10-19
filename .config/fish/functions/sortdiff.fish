#!/usr/bin/env fish
# Filter and sort a git diff showing only the changed lines.
function sortdiff
    git diff $argv \
        | egrep --invert-match "^[+-]{3} " \
        | grep "^[+-]" \
        | sort --key=1.2 \
        | uniq -u -s1
end
