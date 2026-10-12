# delete-tag - Deletes a git tag from both the local and remote repos
export def delete-tag [tag: string] {
    if ($tag | is-empty) {
        error make { msg: "Usage: delete-tag <tag>" }
    }
    let current_branch = (^git rev-parse --abbrev-ref HEAD | str trim)
    let remote = (do { ^git config $"branch.($current_branch).remote" } | complete)
    if $remote.exit_code != 0 or ($remote.stdout | str trim | is-empty) {
        error make { msg: $"No remote configured for branch '($current_branch)' - detached HEAD?; cannot delete remote tag" }
    }
    let current_remote = ($remote.stdout | str trim)

    try { ^git tag --delete $tag } catch { print --stderr $"local tag ($tag) not found; continuing with remote" }
    ^git push $current_remote --delete $"refs/tags/($tag)"
}
