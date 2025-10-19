#!/usr/bin/env fish
# Prints the index of a value in a list.
function index --argument-names value
    if test -z "$value"
        echo "Usage: index value \$list"
        return 1
    end

    contains --index -- $value $argv[2..-1]
end
