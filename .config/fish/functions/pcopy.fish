#!/usr/bin/env fish
# Copy the current dir path into the pasteboard
function pcopy
    pwd | xargs echo -n | pbcopy
end
