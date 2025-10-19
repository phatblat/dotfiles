#!/usr/bin/env fish
function subrepo \
    --description='Wrapper for git-subrepo'

    git subrepo $argv
end
