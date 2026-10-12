# dbg - Prints args only when debug env var is set
export def --wrapped dbg [...args: string] {
    if not ($env.debug? | default "" | is-empty) {
        print $"DEBUG: ($args | str join ' ')"
    }
}
