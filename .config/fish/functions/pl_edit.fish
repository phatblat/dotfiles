# Edit Powerline config files.
function pl_edit
    echo "Kill the powerline-daemon (-k) to see changes."
    ps aux | grep --invert-match 'grep' | grep powerline-daemon
    edit ~/.config/powerline
end
