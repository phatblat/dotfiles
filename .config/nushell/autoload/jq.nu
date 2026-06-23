# Dependencies:
#   functions: none
#   builtins:  print
#   externals: jq

# Wrapper around jq that buffers stdin, runs jq, and prints the original input to stderr on failure
export def --wrapped jq [...rest: string] {
    let input = $in | to text
    let result = do { $input | ^jq ...$rest } | complete
    if $result.exit_code != 0 {
        print --stderr $"jq failed. Input was:\n($input)"
        error make { msg: "jq failed" }
    }
    $result.stdout
}
