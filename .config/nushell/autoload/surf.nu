# Dependencies:
#   functions: none
#   builtins:  is-empty
#   externals: windsurf

# Open a path (or current directory) in Windsurf editor
export def surf [...rest] {
    if ($rest | is-empty) {
        ^windsurf .
    } else {
        ^windsurf ...$rest
    }
}
