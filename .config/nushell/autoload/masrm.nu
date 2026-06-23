# Dependencies:
#   functions: error-msg fileowner masshow
#   builtins:  which is-empty path join path exists str trim
#   externals: brew trash

# Uninstall the mas binary, choosing between trash (root-owned) or brew uninstall (user-owned)
export def masrm [] {
    let mas_found = (which mas | length) > 0
    if not $mas_found {
        error-msg "mas is not installed"
        return
    }

    let brew_prefix = (^brew --prefix | str trim)
    let binary = ($brew_prefix | path join "bin" "mas")

    if not ($binary | path exists) {
        error-msg $"No mas found at ($binary)"
        return
    }

    let owner = (fileowner $binary)
    if $owner == "root" {
        ^trash $binary
    } else if $owner == $env.USER {
        ^brew uninstall mas
    }

    let still_found = (which mas | length) > 0
    if $still_found {
        error-msg "Another copy of mas is still installed"
        masshow
    }
}
