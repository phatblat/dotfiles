# Dependencies:
#   functions: none
#   builtins:  none
#   externals: ssh

# SSH into octodec.local as phatblat, forwarding all arguments to the remote shell
export def --wrapped octodec [...rest] {
    ^ssh phatblat@octodec.local ...$rest
}
