# Dependencies:
#   functions: none
#   builtins:  error is-empty
#   externals: shasum

# Display the SHA1 hash of one or more files
export def sha1 [...files: string] {
    if ($files | is-empty) {
        error make { msg: "Usage: sha1 file1 file2..." }
    }
    ^shasum --algorithm 1 ...$files
}
