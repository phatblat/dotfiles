# cask_dir - Quick nav to the Homebrew Casks tap
export def --env cask_dir [] {
    let repo = (^brew --repository | str trim)
    cd $"($repo)/Library/Taps/homebrew/homebrew-cask/Casks"
}
