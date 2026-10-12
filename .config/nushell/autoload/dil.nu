# dil - List docker images
export def --wrapped dil [...args] {
    ^docker images ...$args
}
