# Dependencies:
#   functions: none
#   builtins:  error is-empty lines any
#   externals: brew

# Check whether a Homebrew formula is currently installed
export def brew_installed [formula: string] {
    if ($formula | is-empty) {
        error make { msg: "Usage: brew_versions formula" }
    }
    let installed = (^brew list -1 | lines | any {|f| $f == $formula })
    if $installed {
        print $"($formula) is installed."
    } else {
        error make { msg: $"($formula) is not installed." }
    }
}
