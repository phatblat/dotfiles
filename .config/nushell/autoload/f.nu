# Dependencies:
#   functions: fork
#   builtins:  none
#   externals: none

# Short alias for invoking fork. Given no args, the current folder will be opened
export def --wrapped f [...rest] {
    if ($rest | is-empty) {
        fork .
    } else {
        fork ...$rest
    }
}
