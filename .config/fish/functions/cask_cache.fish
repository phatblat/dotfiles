#!/usr/bin/env fish
# Manage the Homebrew Cask cache. Without args the contents of the cache are displayed.
function cask_cache --argument-names command
    if test -z "$command"
        set command show
    end

    switch $command
        case clean
            trash -v ~/Library/Caches/Homebrew/Cask
        case show
            echo "Homebrew Cask cache is user-specific"
            ll -1d ~/Library/Caches/Homebrew/Cask
            ll ~/Library/Caches/Homebrew/Cask
        case '*'
            # Show usage
            echo "Usage: cask_cache arg1"
            return 1
    end
end
