# configg - Manage global git configuration (~/.config/git/config)
export def configg [...args] {
    ^git config --global ...$args
}
