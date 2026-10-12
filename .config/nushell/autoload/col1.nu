# col1 - Prints the first column of input (first argument)
# Multi-line content can be passed on stdin, assumed when given no arguments, or
# a single dash.
export def col1 [input?: string] {
    if ($input == null) or ($input == "-") {
        $in | ^awk '{print $1}'
    } else {
        $input | ^awk '{print $1}'
    }
}
