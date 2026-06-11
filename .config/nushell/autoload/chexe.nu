# Dependencies:
#   functions: none
#   builtins:  glob is-empty
#   externals: chmod

# Set executable permissions on files; defaults to *.sh in current directory
export def chexe [...files: string] {
    let targets = if ($files | is-empty) {
        glob "*.sh"
    } else {
        $files
    }
    ^chmod +x ...$targets
}
