#!/usr/bin/env fish
function bpu \
    --description='Update pods without updating repos.'

    bundle exec "pod update --no-repo-update $argv"
end
