# dtc - Git difftool on cached/staged changes
export def dtc [...args] {
    ^git difftool --cached ...$args
}
