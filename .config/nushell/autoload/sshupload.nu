# sshupload - Uploads public SSH key to GitHub profile
# Requires DOTFILES_GITHUB_TOKEN environment variable
export def sshupload [keyfile?: string] {
    let kf = if ($keyfile | is-empty) { (sshkey) } else { $keyfile }

    if not ($kf | path exists) {
        print --stderr $"Error: No SSH key found at ($kf)"
        error make { msg: $"No SSH key found at ($kf)" }
    }

    let token = ($env.DOTFILES_GITHUB_TOKEN? | default "")
    if ($token | is-empty) {
        print --stderr "Error: Please set DOTFILES_GITHUB_TOKEN in .envrc"
        error make { msg: "DOTFILES_GITHUB_TOKEN not set" }
    }

    let key = (open --raw $kf | str trim)
    let host = (^hostname | str trim)
    let ts = (date now | format date "%Y%m%d%H%M%S")
    let title = $"($env.USER)@($host)_($ts)"

    print $"Uploading SSH public key to GitHub [($kf)]"

    ^curl --request POST --url "https://api.github.com/user/keys" --header $"Authorization: token ($token)" --data $"{\"title\":\"($title)\",\"key\":\"($key)\"}" --verbose
}
