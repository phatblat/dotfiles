# Dependencies:
#   functions: none
#   builtins:  path exists print mv str replace str ends-with
#   externals: none

# Toggle .bak extension: adds .bak if missing, removes it if already present
export def bak [file: string] {
    # Strip trailing slash from dir autocompletion
    let file = $file | str replace --regex '/$' ''

    if not ($file | path exists) {
        error make { msg: $"'($file)' does not exist" }
    }

    if ($file | str ends-with ".bak") {
        let new_name = $file | str replace --regex '\.bak$' ''
        mv $file $new_name
        print $"Renamed to '($new_name)'"
    } else {
        let new_name = $"($file).bak"
        mv $file $new_name
        print $"Renamed to '($new_name)'"
    }
}
