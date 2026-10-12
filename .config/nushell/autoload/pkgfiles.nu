# pkgfiles - Shows files associated with the given installer package
export def pkgfiles [package_identifier: string] {
    if ($package_identifier | is-empty) {
        error make { msg: "Usage: pkgfiles package_identifier" }
    }
    ^pkgutil --files $package_identifier
}
