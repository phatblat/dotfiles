#!/usr/bin/env fish
# Lists installed versions of a formula.
function brew_versions --argument-names formula
    if test -z "$formula"
        echo "Usage: brew_versions formula"
        return 1
    else if not brew_installed $formula
        echo "$formula is not installed." >&2
        return 2
    end

    # brew list --versions ruby output:
    # ruby 2.3.3 2.4.1_1
    list (list -s (brew list --versions $formula))[2..-1]
end
