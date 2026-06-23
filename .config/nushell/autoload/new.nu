# Dependencies:
#   functions: none
#   builtins:  is-empty first skip
#   externals: git

# List new commits introduced since the last pull (uses reflog @{1}..@{0})
export def new [...rest: string] {
    let commit = if ($rest | is-empty) { "HEAD" } else { $rest | first }
    let extra = if ($rest | length) > 1 { $rest | skip 1 } else { [] }
    let start_commit = (^git rev-parse $"($commit)@{1}" | str trim)
    let end_commit   = (^git rev-parse $"($commit)@{0}" | str trim)
    ^git log --boundary $"($start_commit)..($end_commit)" ...$extra
}
