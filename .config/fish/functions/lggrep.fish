#!/usr/bin/env fish
# Grep through lightweight log `lg` for a regex pattern.
function lggrep --argument-names pattern
    if test -z "$pattern"
        echo Usage: lggrep '.*'
        return 1
    end

    lg -G $pattern
end
