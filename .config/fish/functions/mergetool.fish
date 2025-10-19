#!/usr/bin/env fish
# Perform a git merge using the configured tool (Kaleidoscope).
function mergetool
    git mergetool $argv
end
