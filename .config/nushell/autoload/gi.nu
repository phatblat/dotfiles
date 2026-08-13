# Dependencies:
#   functions: none
#   builtins:  error is-empty
#   externals: curl

# Generate a .gitignore file using gitignore.io
export def gi [...types: string] {
    if ($types | is-empty) {
        error make { msg: "Usage: gi type1,type2,..." }
    }
    let query = ($types | str join ",")
    ^curl -L -s $"https://www.gitignore.io/api/($query)"
}
