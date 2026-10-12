# ldot - List hidden files
export def --wrapped ldot [...args] {
    let dots = (ls -a | where name starts-with '.' and name not-in ['.' '..'] | get name)
    if ($dots | is-empty) { error make { msg: "no matches found: .*" } }
    ^ls -ld ...$dots ...$args
}
