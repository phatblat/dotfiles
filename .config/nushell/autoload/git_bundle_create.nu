# Dependencies:
#   functions: none
#   builtins:  lines first split get date print
#   externals: git

# Creates a git bundle containing any changes in the working copy and index
# that haven't been committed
export def git_bundle_create []: nothing -> nothing {
    let bundle_name = "snapshot.bundle"
    let repo_path = $env.PWD
    let current_branch = (^git rev-parse --abbrev-ref HEAD)

    # Show current location
    print $repo_path

    # Snapshot
    print $"current branch: ($current_branch)"
    let head_sha = (^git rev-parse HEAD)
    print $"HEAD: ($head_sha)"
    ^git stash list
    ^git stash save --include-untracked $"snapshot: (date now | format date '%Y-%m-%d %H:%M:%S')"

    # Returns only the SHA of the last stash
    let snapshot_sha = (^git show --pretty=oneline 'refs/stash@{0}' | lines | first | split column ' ' | get column1.0)
    print $"snapshot: ($snapshot_sha)"

    # Create bundle
    do { ^git tag -d snapshot_end } | ignore
    ^git tag snapshot_end $snapshot_sha

    # This requires the HEAD commit to be present in the local repo
    ^git bundle create $bundle_name $"HEAD..snapshot_end"
    ^git bundle verify $bundle_name
    do { ^git tag -d snapshot_end } | ignore
}
