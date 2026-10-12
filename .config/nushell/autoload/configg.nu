# configg - Manage global git configuration (~/.config/git/config)
export def --wrapped configg [...args] {
    ^git config --global ...$args
}
