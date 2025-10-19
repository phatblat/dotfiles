#!/usr/bin/env fish
# brew_active_version
function brew_active_version --argument-names formula
    if test -z "$formula"
        echo "Usage: brew_active_version formula"
        return 1
    end

    string replace --all '"' '' (bq $formula | jq .[0].linked_keg)
end
