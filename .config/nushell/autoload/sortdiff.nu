# Dependencies:
#   functions: none
#   builtins:  lines where str starts-with str substring group-by transpose get length sort-by str join
#   externals: git

# Filter and sort a git diff showing only changed lines unique by content (mirrors the original moved-line filtering)
export def sortdiff [...args: string] {
    let raw = (^git diff ...$args)
    let changed = ($raw
        | lines
        | where {|l| ($l | str starts-with "+") or ($l | str starts-with "-") }
        | where {|l| not (($l | str starts-with "+++") or ($l | str starts-with "---")) })

    $changed
        | group-by {|l| $l | str substring 1.. }
        | transpose key lines
        | where {|row| ($row.lines | length) == 1 }
        | get lines
        | flatten
        | sort-by {|l| $l | str substring 1.. }
        | str join "\n"
}
