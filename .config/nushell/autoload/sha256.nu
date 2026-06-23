# Dependencies:
#   functions: none
#   builtins:  is-empty
#   externals: shasum

# Compute SHA-256 checksums of one or more files
export def sha256 [...files: path] {
    if ($files | is-empty) {
        error make { msg: "Usage: sha256 file1 file2..." }
    }
    ^shasum --algorithm 256 ...$files
}
