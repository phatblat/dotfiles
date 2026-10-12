# pl_edit - Edit Powerline config files
const psgrep_nu = path self psgrep.nu
source $psgrep_nu
export def pl_edit [] {
    print "Kill the powerline-daemon (-k) to see changes."
    psgrep powerline-daemon | print
    let editor = ($env.EDITOR? | default "vim")
    ^$editor ($env.HOME | path join ".config" "powerline")
}
