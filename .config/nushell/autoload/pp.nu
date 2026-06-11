# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Publish the current branch to the phatblat remote
export def pp [] {
    let branch = (^git rev-parse --abbrev-ref HEAD | str trim)
    ^git push -u phatblat $branch
}
