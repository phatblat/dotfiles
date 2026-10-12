# ccu - Update dependencies without building using Carthage
export def --wrapped ccu [...args] {
    ^carthage update --no-use-binaries --no-build ...$args
}
