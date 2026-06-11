# Dependencies:
#   functions: none
#   builtins:  is-empty
#   externals: pkgutil

# Show metadata for the given installer package identifier
export def pkginfo [package_id: string] {
    if ($package_id | is-empty) {
        error make { msg: "Usage: pkginfo package_identifier" }
    }
    ^pkgutil --pkg-info $package_id
}
