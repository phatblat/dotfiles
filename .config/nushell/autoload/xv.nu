# xv - Prints Xcode version information
export def --wrapped xv [...args] {
    ^xcodebuild -version ...$args
}
