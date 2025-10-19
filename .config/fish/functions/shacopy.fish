#!/usr/bin/env fish
# Copies the SHA1 hash of the HEAD commit to the general pasteboard.
function shacopy
    headsha | pbcopy
end
