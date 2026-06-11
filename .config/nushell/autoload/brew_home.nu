# Dependencies:
#   functions: is_mac is_linux
#   builtins:  print
#   externals: brew

# Print the Homebrew home dir, or the cellar path for a specific formula
export def --env brew_home [
    formula?: string   # Optional formula name; prints prefix/opt/<formula> when given
] {
    source /Users/phatblat/.config/nushell/autoload/is_mac.nu
    source /Users/phatblat/.config/nushell/autoload/is_linux.nu

    # Populate $env.BREW_HOME only when not already set
    if ($env.BREW_HOME? | is-empty) {
        let brew_prefix = (
            try { ^brew --prefix | str trim } catch { "" }
        )
        $env.BREW_HOME = if ($brew_prefix | is-not-empty) {
            $brew_prefix
        } else if (is_mac) {
            if $nu.os-info.arch == "aarch64" {
                "/opt/homebrew"
            } else {
                "/usr/local"
            }
        } else if (is_linux) {
            "/home/linuxbrew/.linuxbrew"
        } else {
            ""
        }
    }

    if ($formula | is-empty) {
        print $env.BREW_HOME
    } else {
        print $"($env.BREW_HOME)/opt/($formula)"
    }
}
