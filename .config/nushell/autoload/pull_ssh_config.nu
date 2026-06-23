# Dependencies:
#   functions: none
#   builtins:  str trim print
#   externals: hostname scp

# Copy SSH config from phatmini.c4 to local ~/.ssh/config (guarded against running on phatmini)
export def pull_ssh_config [] {
    let host = (^hostname | str trim)
    if $host == "phatmini" {
        print --stderr "pull_ssh_config should be run on a remote host"
        return
    }
    ^scp $"phatmini.c4:.ssh/config" $"($env.HOME)/.ssh/config"
}
