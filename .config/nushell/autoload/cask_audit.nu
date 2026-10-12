# cask_audit - Audits a Homebrew cask
export def cask_audit [token: string] {
    if ($token | is-empty) {
        error make { msg: "Usage: cask_audit token" }
    }
    let info = (do { ^brew info --cask $token } | complete)
    if $info.exit_code != 0 {
        error make { msg: $"Cask ($token) does not exist." }
    }
    ^brew audit --cask $token --download
    ^brew style --cask $token --fix
}
