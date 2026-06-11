# Dependencies:
#   functions: none
#   builtins:  print is-empty length skip for
#   externals: none

# Print each argument on its own line; -s skips the first arg (label convention)
export def list [-s, ...items: string] {
    if ($items | is-empty) {
        print --stderr "Usage: list [-s] 1 2 3 4 ..."
        error make { msg: "list: no arguments provided" }
    }
    let output = if $s {
        if (($items | length) < 1) {
            print --stderr "Usage: list -s 1 2 3 4 ..."
            error make { msg: "list: no items after -s" }
        }
        $items | skip 1
    } else {
        $items
    }
    for it in $output {
        print $it
    }
}
