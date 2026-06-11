# Dependencies:
#   functions: error-msg brew_home
#   builtins:  open str contains print
#   externals: sudo sh

# Register a new shell in /etc/shells (Homebrew-managed shells only)
export def shell_add [
    new_shell: string   # Shell name (e.g. bash, zsh, fish)
] {
    source /Users/phatblat/.config/nushell/autoload/error-msg.nu
    source /Users/phatblat/.config/nushell/autoload/brew_home.nu

    let system_shells_file = "/etc/shells"
    let brew_bin = (brew_home) | str trim
    let new_shell_path = $"($brew_bin)/($new_shell)"

    if not ($new_shell_path | path exists) {
        error-msg $"No such file: ($new_shell_path)"
        return 2
    }

    let system_shells = (open $system_shells_file | lines | where { |l| $l | str starts-with $brew_bin })

    if not ($system_shells | str join "\n" | str contains $new_shell_path) {
        print $"Adding ($new_shell_path) to ($system_shells_file)"
        ^sudo sh -c $"echo '($new_shell_path)' >> ($system_shells_file)"
    } else {
        print $"($new_shell_path) is already registered"
    }

    open $system_shells_file
}
