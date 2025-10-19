#!/usr/bin/env fish
# Audits a Homebrew cask.
function cask_audit --argument-names token
    if test -z "$token"
        echo "Usage: cask_audit token"
        return 1
    end
    # switch $arg1
    #     case on ON On
    #     case off OFF Off
    #     case '*'
    # end

    if brew cask info $token >/dev/null 2>&1
        brew cask audit $token --download
        brew cask style $token --fix
    else
        echo "Cask $token does not exist."
        return 2
    end
end
