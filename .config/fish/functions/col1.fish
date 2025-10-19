#!/usr/bin/env fish
# Prints the first column of input (first argument).
# Multi-line content can be passed on stdin, assumed when given no arguments, or
# a single dash.
function col1 --argument-names arg1
    if test (count "$argv") -ge 0 -o "$argv" = -
        # Input is from stdin
        cat | awk '{print $1}'
    end

    # Substring up to the first space
    echo $arg1 | awk '{print $1}'
end
