# Dependencies:
#   functions: none
#   builtins:  history where
#   externals: none

# Search shell command history for a pattern
export def hgrep [pattern: string] {
    history | where command =~ $pattern
}
