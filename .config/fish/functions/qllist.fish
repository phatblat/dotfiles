#!/usr/bin/env fish
# List QuickLook plugins.
function qllist
    qlmanage -m plugins $argv
end
