#!/usr/bin/env fish
function dirty \
    --description 'Show repo dirty files'

    git clean -xd --force --dry-run
end
