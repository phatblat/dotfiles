#!/usr/bin/env fish
# Scans through installer package identifiers for the given name.
function pkgfind --argument-names filter
    if test -z $filter
        echo "Usage: pkgfind name"
        return 1
    end

    pkgutil --packages | grep -i $filter
end
