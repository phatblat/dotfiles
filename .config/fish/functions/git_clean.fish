#!/usr/bin/env fish
function git_clean \
    --description='Clean non-tracked files from the working tree'
    git clean -xffd
end
