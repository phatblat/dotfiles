# Dependencies:
#   functions: none
#   builtins:  none
#   externals: ssh

# Test SSH connection to GitHub (ssh -T returns exit 1 on success; suppress via do)
export def sshtest [] {
    do { ^ssh -T git@github.com }
}
