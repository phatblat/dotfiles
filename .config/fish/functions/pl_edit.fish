#!/usr/bin/env fish
# Edit Powerline config files.
function pl_edit
    echo "Kill the powerline-daemon (-k) to see changes."
    psgrep powerline-daemon
    edit ~/.config/powerline
end
