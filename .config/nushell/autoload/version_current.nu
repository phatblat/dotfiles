# version_current - Displays Xcode project version information
export def version_current [] {
    let market = (version_market)
    let build = (version_build)
    print $"($market) \(($build)\)"
}
