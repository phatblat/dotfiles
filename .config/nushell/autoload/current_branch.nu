# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Displays the current branch name
export def current_branch [...args: string]: nothing -> string {
    ^git rev-parse --abbrev-ref HEAD ...$args
}
