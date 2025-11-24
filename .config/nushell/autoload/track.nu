export def track [remote_branch?: string, local_name?: string] {
    if $remote_branch == null {
        print "Usage: track remote_branch [local_name]"
        return
    }
    if $local_name == null {
        ^git checkout --track $remote_branch
    } else {
        ^git checkout --track $remote_branch -b $local_name
    }
}
