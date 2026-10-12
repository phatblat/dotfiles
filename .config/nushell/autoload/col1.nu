# col1 - Prints the first column of input (first argument)
# Multi-line content can be passed on stdin, assumed when given no arguments, or
# a single dash.
export def col1 [input?: string] {
    if ($input == null) or ($input == "-") {
        # No `$in |`: pipeline input flows implicitly, and when nothing is piped
        # the external inherits the real stdin (so `col1 < file` works).
        ^awk '{print $1}'
    } else {
        $input | ^awk '{print $1}'
    }
}
