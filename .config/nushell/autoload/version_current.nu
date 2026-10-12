# version_current - Displays Xcode project version information
const version_market_nu = path self version_market.nu
source $version_market_nu
export def version_current [] {
    let market = (version_market)
    let build = (version_build)
    print $"($market) \(($build)\)"
}
