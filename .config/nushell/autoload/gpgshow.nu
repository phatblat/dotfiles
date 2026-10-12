# gpgshow - List GPG keys with short keyid format
export def --wrapped gpgshow [...args: string] {
    ^gpg --list-keys --keyid-format short ...$args
}
