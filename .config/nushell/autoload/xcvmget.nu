# xcvmget - Show a live list of Xcode versions available to download
export def xcvmget [] {
    let script = ($nu.default-config-dir | path join autoload xcvmget.rb)
    ^bundle exec ruby $script
}
