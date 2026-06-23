# Dependencies:
#   functions: none
#   builtins:  path exists print cd
#   externals: git

# Clone a fresh copy or pull an existing git repo
export def clone_or_pull [
    folder: string   # Local folder path
    git_url: string  # Git remote URL
    branch?: string  # Optional branch to checkout
] {
    if not ($folder | path exists) {
        ^git clone $git_url $folder
        if ($branch | is-not-empty) {
            cd $folder
            ^git checkout $branch
            cd ..
        }
    } else {
        let current_branch = (^git -C $folder rev-parse --abbrev-ref HEAD | str trim)
        if ($branch | is-not-empty) and $branch != $current_branch {
            print $"WARNING: ($folder) currently has the ($current_branch) branch checked out (!=($branch))"
        }
        ^git -C $folder pull
    }
}
