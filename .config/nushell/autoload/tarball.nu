# Dependencies:
#   functions: none
#   builtins:  error is-empty
#   externals: tar

# Create a compressed tarball from a file or directory
export def tarball [file_or_dir: string] {
    if ($file_or_dir | is-empty) {
        error make { msg: "Usage: tarball file_or_dir" }
    }
    ^tar -zcvf $"($file_or_dir).tar.gz" $file_or_dir
}
