# Dependencies:
#   functions: none
#   builtins:  lines split column split row uniq-by
#   externals: git

# List git remote details
export def rv [] {
    let remotes = ^git remote -v | lines

    if ($remotes | is-empty) {
        print "No remotes are currently defined."
        return
    }

    $remotes
    | split column "\t" remote rest
    | each {|row| {remote: $row.remote, url: ($row.rest | split row " " | first)} }
    | uniq-by remote
}
