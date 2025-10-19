#!/usr/bin/env fish
# Update depencencies without building using Carthage over SSH.
function ccus
    carthage update --no-use-binaries --no-build --use-ssh $argv
end
