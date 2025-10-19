#!/usr/bin/env fish
# Displays files not tracked in the current git repo.
function untracked
    git ls-files --others --exclude-standard $argv
end
