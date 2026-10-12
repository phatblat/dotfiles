# dash - Dash shell integration
export def dash [query: string] {
    if ($query | is-empty) {
        error make { msg: "Usage: dash query   (prefix query with 'docset_name:' to limit)" }
    }
    ^open $"dash://($query)"
}
