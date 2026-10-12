# dtc - Git difftool on cached/staged changes
export def --wrapped dtc [...args] {
    ^git difftool --cached ...$args
}
