# Dependencies:
#   functions: none
#   builtins:  error is-empty default
#   externals: curl

# Validate the GitHub personal access token in GITHUB_TOKEN
export def gh_token_test [] {
    let token = ($env.GITHUB_TOKEN? | default "")
    if ($token | is-empty) {
        error make { msg: "Please set GITHUB_TOKEN in .env" }
    }
    ^curl -s -u $"phatblat:($token)" https://api.github.com/user
}
