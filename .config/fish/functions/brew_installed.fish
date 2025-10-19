#!/usr/bin/env fish
# Checks whether a formula is currently installed.
function brew_installed --argument-names formula
    if test -z "$formula"
        echo "Usage: brew_versions formula"
        return 1
    else if not brew list -1 | grep --silent --line-regexp $formula
        echo "$formula is not installed." >&2
        return 2
    end

    echo "$formula is installed."
end
