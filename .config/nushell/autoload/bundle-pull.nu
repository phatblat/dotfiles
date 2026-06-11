# Dependencies:
#   functions: git_inside_repo git_repo_dirty git_repo_clean repeatchar current_branch git_bundle_create
#   builtins:  path relative-to print
#   externals: ssh rsync git rm hostname

# Copies a dirty working copy from one host to another via git bundle
export def "bundle-pull" []: nothing -> nothing {
    source /Users/phatblat/.config/nushell/autoload/git_inside_repo.nu
    source /Users/phatblat/.config/nushell/autoload/git_repo_dirty.nu
    source /Users/phatblat/.config/nushell/autoload/git_repo_clean.nu
    source /Users/phatblat/.config/nushell/autoload/repeatchar.nu
    source /Users/phatblat/.config/nushell/autoload/current_branch.nu
    source /Users/phatblat/.config/nushell/autoload/git_bundle_create.nu

    # Ensure current dir is in a clean git repo
    if not (git_inside_repo) {
        error make { msg: "This command must be run inside a git repo." }
    }

    if (git_repo_dirty) {
        error make { msg: "The work tree is dirty, aborting." }
    }

    let bundle_name = "snapshot.bundle"
    let local_username = $env.USER
    let local_hostname = (^hostname)

    let remote_info = (match $local_hostname {
        "protop" => { hostname: "phatmini", username: "phatblat" },
        "phatmini" => { hostname: "protop", username: "phatblat" },
        _ => null
    })

    if $remote_info == null {
        error make { msg: $"Unknown hostname: ($local_hostname)" }
    }

    let remote_hostname = $remote_info.hostname
    let remote_username = $remote_info.username

    # Use a path relative to HOME to avoid user mismatches
    let repo_path = ($env.PWD | path relative-to ($env.HOME))
    let branch = (current_branch)

    repeatchar "-"

    # Remote
    print $"Creating bundle on ($remote_hostname):($repo_path)/($bundle_name)"
    print ""

    # Create a git bundle file containing the diff of the working copy to HEAD.
    ^ssh $"($remote_username)@($remote_hostname)" $"nu -c \"source ~/.config/nushell/autoload/git_bundle_create.nu; cd '($repo_path)'; git_bundle_create\""

    repeatchar "-"

    print $"Downloading bundle to ($local_hostname):($repo_path)/($bundle_name)"
    print ""

    let source = $"($remote_username)@($remote_hostname):($repo_path)/($bundle_name)"
    let destination = $"($env.HOME)/($repo_path)/($bundle_name)"

    # rsync preserves paths, scp doesn't
    ^rsync --archive --recursive --compress --verbose $source $destination

    # Delete the bundle from the remote after successful transfer
    ^ssh $"($remote_username)@($remote_hostname)" $"rm --verbose '($repo_path)/($bundle_name)'"
    ^git bundle list-heads snapshot.bundle

    repeatchar "-"

    # Local
    print $"Extracting bundle on ($local_hostname)"
    print ""

    ^git fetch snapshot.bundle "refs/tags/snapshot_end:snapshot"
    ^git tag before_bundle_pull
    ^git checkout snapshot
    ^git reset --mixed before_bundle_pull

    # Cleanup
    ^git checkout $branch
    ^git branch --delete snapshot
    ^git tag -d before_bundle_pull
    ^git tag -d snapshot_end
    ^rm $bundle_name
}
