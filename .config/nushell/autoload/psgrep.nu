# Dependencies:
#   functions: none
#   builtins:  ps where is-empty error
#   externals: none

# Search running processes by name pattern
export def psgrep [pattern: string] {
    if ($pattern | is-empty) {
        error make { msg: "Usage: psgrep process_name" }
    }
    ps | where name =~ $pattern
}
