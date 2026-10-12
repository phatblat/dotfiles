# pkgfind - Scans through installer package identifiers for the given name
export def pkgfind [name: string] {
    if ($name | is-empty) {
        error make { msg: "Usage: pkgfind name" }
    }
    ^pkgutil --pkgs | lines | where {|l| $l | str contains --ignore-case $name }
}
