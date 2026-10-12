# cask_token - Generates a cask token for an app
export def cask_token [path: string] {
    if ($path | is-empty) {
        error make { msg: "Usage: cask_token path/to/software.app" }
    }
    if not ($path | path exists) {
        error make { msg: $"($path) does not exist" }
    }
    let repo = (^brew --repository | str trim)
    let generator = $"($repo)/Library/Taps/homebrew/homebrew-cask/developer/bin/generate_cask_token"
    ^$generator $path
}
