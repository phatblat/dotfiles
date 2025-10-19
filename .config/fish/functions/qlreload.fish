#!/usr/bin/env fish
# Reload QuickLook plugins.
function qlreload
    qlmanage -r $argv
end
