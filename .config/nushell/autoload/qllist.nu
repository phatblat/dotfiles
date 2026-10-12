# qllist - List QuickLook plugins
export def qllist [...args] {
    ^qlmanage -m plugins ...$args
}
