# xv - Prints Xcode version information
export def xv [...args] {
    ^xcodebuild -version ...$args
}
