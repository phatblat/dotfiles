# repo_new - Creates a new GitHub repo using the local dir as the root
export def repo_new [repo_name: string] {
    if ($repo_name | is-empty) {
        error make { msg: "Usage: repo_new [repo_name]" }
    }
    ^gh repo create $repo_name --public --source=.
    pborigin
    pp
}
