# brew_logs - Quick nav to Homebrew logs dir
export def --env brew_logs [] {
    cd ("~/Library/Logs/Homebrew/" | path expand)
}
