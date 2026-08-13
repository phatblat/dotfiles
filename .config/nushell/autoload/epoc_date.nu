# Dependencies:
#   functions: none
#   builtins:  into int into datetime format date error is-empty
#   externals: none

# Convert an epoch timestamp to a human-readable date
export def epoc_date [epoc_timestamp: string] {
    if ($epoc_timestamp | is-empty) {
        error make { msg: "Usage: epoc_date epoc_timestamp" }
    }
    ($epoc_timestamp | into int) * 1_000_000_000 | into datetime --timezone UTC | format date "%Y-%m-%d"
}
