#!/usr/bin/env fish
function ghostty \
    --description='Wrapper for Ghostty terminal emulator.'

    set ghostty_bin /Applications/Ghostty.app/Contents/MacOS/ghostty

    if not test -x $ghostty_bin
        echo "Error: Ghostty not found at $ghostty_bin" >&2
        echo "Install via: brew install --cask ghostty" >&2
        return 1
    end

    $ghostty_bin $argv
end
