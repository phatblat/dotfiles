#!/usr/bin/env fish
function bpuru \
    --description='Update pods after updating repos.'

    bundle exec "pod update $argv"
end
