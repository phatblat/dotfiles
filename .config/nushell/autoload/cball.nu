# cball - Build all platforms using Carthage
export def cball [...args] {
    ^carthage build --platform all ...$args
}
