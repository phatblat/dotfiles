#!/usr/bin/env fish
function review-pr \
    --description='Review a GetDitto GitHub PR with OMP and preserve interactive follow-up.'

    if test (count $argv) -eq 0
        echo "Usage: review-pr <github-pr-url|repo#number|getditto/repo#number>"
        return 1
    end

    ~/scripts/review-pr.py $argv
end
