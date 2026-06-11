# Dependencies:
#   functions: none
#   builtins:  is-empty
#   externals: git

# Restore files in the git index from HEAD (unstage staged changes)
export def unstage [...files: string] {
    if ($files | is-empty) {
        ^git restore --staged .
    } else {
        ^git restore --staged ...$files
    }
}
