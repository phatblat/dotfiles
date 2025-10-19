#!/usr/bin/env fish
function gc \
    --description='Run git garbage collection'

    git gc --prune=now
end
