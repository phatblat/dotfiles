# Dependencies:
#   functions: is_linux is_mac user_is_admin
#   builtins:  print
#   externals: brew chsh dscl sudo

# Change the current user's login shell using dscl (macOS) or chsh (Linux)
export def shell_switch [
    new_shell: string   # Shell name (e.g. bash, zsh, fish)
] {
    if ($new_shell | is-empty) {
        error make { msg: "Usage: shell_switch bash|zsh|fish" }
    }

    let brew_bin = (^brew --prefix | str trim) + "/bin"
    let new_shell_path = $"($brew_bin)/($new_shell)"
    let current_shell = ($env.SHELL | path basename)

    if $current_shell == $new_shell {
        print "No changes."
        return
    }

    if (is_linux) {
        ^chsh --shell $new_shell_path
        return
    }

    # macOS: use dscl
    let cmd = $"sudo dscl . -change ($env.HOME) UserShell ($env.SHELL) ($new_shell_path)"
    if (user_is_admin) {
        ^sudo dscl . -change $env.HOME UserShell $env.SHELL $new_shell_path
        print -n $"Changed (^dscl . -read $env.HOME UserShell | str trim)"
        print ""
        ^$new_shell_path
    } else {
        print "Have an admin run the following command:"
        print $"    ($cmd)"
    }
}
