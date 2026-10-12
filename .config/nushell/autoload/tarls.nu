# tarls - List contents of a tarball
export def tarls [file?: string] {
    if ($file | is-empty) {
        print --stderr "Usage: tarls [file_name]"
        error make { msg: "tarls requires a file argument" }
    }

    ^tar -ztvf $file
}
