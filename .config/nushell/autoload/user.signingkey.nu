# user.signingkey - Manages the user.signingkey git configuration setting
export def --wrapped user.signingkey [...args] {
    ^git config user.signingkey ...$args
}
