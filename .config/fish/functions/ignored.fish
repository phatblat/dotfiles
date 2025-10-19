#!/usr/bin/env fish
function ignored \
    --description='Show files ignored by git'

    git status --ignored --porcelain 2>/dev/null
end
