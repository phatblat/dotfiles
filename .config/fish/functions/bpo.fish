#!/usr/bin/env fish
# List outdated pods.
function bpo
    bundle exec "pod outdated --no-repo-update $argv"
end
