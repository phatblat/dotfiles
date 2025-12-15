# Wrapper for Ghostty terminal emulator
export def ghostty [...args] {
    let ghostty_bin = "/Applications/Ghostty.app/Contents/MacOS/ghostty"

    if not ($ghostty_bin | path exists) {
        print $"Error: Ghostty not found at ($ghostty_bin)"
        print "Install via: brew install --cask ghostty"
        return (error make {msg: "Ghostty binary not found"})
    }

    ^$ghostty_bin ...$args
}
