#!/usr/bin/env fish
function review-pr \
    --description='Review a GetDitto GitHub PR with Codex and filter existing threads.'

    if test (count $argv) -eq 0
        echo "Usage: review-pr [--continue] <github-pr-url|repo#number|getditto/repo#number>"
        return 1
    end

    ~/scripts/review-pr.py $argv
end
