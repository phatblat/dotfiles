# xps - Short alias for displaying nginx status
source ~/.config/nushell/autoload/psgrep.nu

export def xps [] {
    psgrep nginx
}
