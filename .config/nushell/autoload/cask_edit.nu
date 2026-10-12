# cask_edit - Manage Homebrew casks
export def --env cask_edit [token: string, cask_version?: string] {
    if ($token | is-empty) {
        error make { msg: "Usage: cask_edit token [cask_version]" }
    }
    let branch = if ($cask_version | is-empty) {
        $token
    } else {
        $"($token)-($cask_version)"
    }

    cask_dir
    ^git checkout master
    ^git pull
    ^git checkout -b $branch

    let info = (do { ^brew info --cask $token } | complete)
    if $info.exit_code == 0 {
        # If token exists, edit it
        ^brew edit --cask $token
    } else {
        # Otherwise, create
        ^brew create --cask $token
    }
}
