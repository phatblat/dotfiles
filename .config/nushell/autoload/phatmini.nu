# Dependencies:
#   functions: none
#   builtins:  none
#   externals: ssh

# SSH shortcut to phatblat@phatmini.local, forwarding all arguments
export def --wrapped phatmini [...rest] {
    ^ssh phatblat@phatmini.local ...$rest
}
