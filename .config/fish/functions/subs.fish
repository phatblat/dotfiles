#!/usr/bin/env fish
# Shows special submodule entries in index
function subs
    git ls-files --stage | grep 160000
end
