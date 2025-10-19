#!/usr/bin/env fish
# Perform a git diff using the configured tool (Kaleidoscope).
function difftool
    git difftool $argv
end
