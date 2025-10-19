#!/usr/bin/env fish
# List outdated gems in the bundle.
function bo
    bundle outdated $argv
end
