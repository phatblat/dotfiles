# user_present - Indicates whether a user is present (interactive session)
# Zsh checked login + interactive + monitor options; nushell approximates
# via $nu.is-interactive, since those zsh-specific option flags do not exist.
export def user_present [] {
    $nu.is-interactive
}
