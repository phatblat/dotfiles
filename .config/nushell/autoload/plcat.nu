# Dependencies:
#   functions: none
#   builtins:  path exists print is-empty
#   externals: plutil bat

# Convert a plist file to XML and display it with bat syntax highlighting
export def plcat [file: path] {
    if ($file | is-empty) {
        error make { msg: "Usage: plcat file" }
    }
    if not ($file | path exists) {
        error make { msg: $"($file) does not exist" }
    }
    ^plutil -convert xml1 -o - -- $file | ^bat
}
