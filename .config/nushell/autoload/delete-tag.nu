# delete-tag - Deletes a git tag from both the local and remote repos
export def delete-tag [tag: string] {
    if ($tag | is-empty) {
        error make { msg: "Usage: delete-tag <tag>" }
    }
    let current_branch = (^git rev-parse --abbrev-ref HEAD | str trim)
    let current_remote = (^git config $"branch.($current_branch).remote" | str trim)

    ^git tag --delete $tag
    ^git push $current_remote --delete $"refs/tags/($tag)"
}
