# title - Sets window/tab title via TAB_TITLE env var
export def --env title [...name: string] {
    if ($name | is-empty) {
        print "Usage: title Tab Name"
        error make { msg: "title requires a name argument" }
    }

    let joined = ($name | str join " ")
    if $joined == "-" {
        hide-env TAB_TITLE
    } else {
        $env.TAB_TITLE = $joined
    }
}
