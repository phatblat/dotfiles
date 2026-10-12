# pl_edit - Edit Powerline config files
export def pl_edit [] {
    print "Kill the powerline-daemon (-k) to see changes."
    psgrep powerline-daemon
    let editor = ($env.EDITOR? | default "vim")
    ^$editor ($env.HOME | path join ".config" "powerline")
}
