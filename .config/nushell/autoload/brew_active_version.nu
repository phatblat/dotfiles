# Dependencies:
#   functions: none
#   builtins:  is-empty from json get
#   externals: brew

# Return the active linked keg version for a given Homebrew formula
export def brew_active_version [formula: string] {
    if ($formula | is-empty) {
        error make { msg: "Usage: brew_active_version formula" }
    }
    # Get the raw JSON from brew, then extract linked_keg natively
    let info = (^brew info --json=v1 $formula | from json)
    $info | get 0.linked_keg
}
