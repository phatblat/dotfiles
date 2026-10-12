# qllist - List QuickLook plugins
export def --wrapped qllist [...args] {
    ^qlmanage -m plugins ...$args
}
