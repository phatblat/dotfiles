#!/usr/bin/env fish
function review-pr \
    --description='Review a GetDitto GitHub PR with Codex and filter existing threads.' \
    --argument-names pr

    if test -z "$pr"
        echo "Usage: review-pr <github-pr-url|repo#number|getditto/repo#number>"
        return 1
    end

    ~/scripts/review-pr.py "$pr"
end
