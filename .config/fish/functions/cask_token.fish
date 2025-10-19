#!/usr/bin/env fish
# Generates a cask token for an app.
function cask_token --argument-names path
    if test -z "$path"
        echo "Usage: cask_token path/to/software.app"
        return 1
    else if not test -e "$path"
        echo "$path does not exist"
        return 2
    end

    eval (brew --repository)/Library/Taps/homebrew/homebrew-cask/developer/bin/generate_cask_token "$path"
end
