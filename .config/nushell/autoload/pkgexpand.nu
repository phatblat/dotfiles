# pkgexpand - Expands a pkg file
export def pkgexpand [package: string, dest_dir: string] {
    if ($package | is-empty) or ($dest_dir | is-empty) {
        error make { msg: "Usage: pkgexpand package dest_dir" }
    }
    ^pkgutil --expand $package $dest_dir
}
