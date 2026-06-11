# Dependencies:
#   functions: none
#   builtins:  is-empty str trim
#   externals: ssh-keygen hostname

# Generate a new ed25519 SSH key at ~/.ssh/id_ed25519 with an optional comment
export def sshnewkey [
    comment?: string  # Key comment (defaults to USER@hostname)
] {
    let resolved_comment = if ($comment == null or ($comment | str trim | is-empty)) {
        $"($env.USER)@(^hostname | str trim)"
    } else {
        $comment
    }
    let keyfile = $"($env.HOME)/.ssh/id_ed25519"
    ^ssh-keygen -t ed25519 -C $resolved_comment -f $keyfile
}
