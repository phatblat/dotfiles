# cball - Build all platforms using Carthage
export def --wrapped cball [...args] {
    ^carthage build --platform all ...$args
}
