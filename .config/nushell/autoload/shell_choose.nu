# Dependencies:
#   functions: brew_home error-msg shell_add shell_switch
#   builtins:  input print open str contains path basename
#   externals: none

# Interactively prompt the user to change their default login shell
export def shell_choose [] {
    source /Users/phatblat/.config/nushell/autoload/error-msg.nu
    source /Users/phatblat/.config/nushell/autoload/brew_home.nu
    source /Users/phatblat/.config/nushell/autoload/shell_add.nu
    source /Users/phatblat/.config/nushell/autoload/shell_switch.nu

    let shells = ["bash" "zsh" "fish"]
    let current_shell = ($env.SHELL | path basename)

    print $"Your default shell is ($current_shell), would you like to change it?"
    let new_shell = (input $"New shell \(($shells | str join ', ')\): " | str trim)

    if $new_shell == $current_shell {
        print "No changes."
        return 1
    }

    let brew_bin = (brew_home) | str trim
    let new_shell_path = $"($brew_bin)/($new_shell)"

    if not (open "/etc/shells" | str contains $new_shell_path) {
        shell_add $new_shell
    }

    print $"Changing default shell to: ($new_shell)"
    shell_switch $new_shell
}
