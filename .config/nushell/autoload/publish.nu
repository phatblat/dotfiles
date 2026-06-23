# Dependencies:
#   functions: none
#   builtins:  str trim
#   externals: git

# Publish the current branch to the named remote
export def publish [remote: string] {
    let branch = (^git rev-parse --abbrev-ref HEAD | str trim)
    ^git push -u $remote $branch
}
