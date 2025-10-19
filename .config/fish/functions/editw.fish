#!/usr/bin/env fish
# Edit (and wait) using the configured VISUAL editor (TextMate),
# blocking the shell from progressing until the editor is closed.
function editw
    toggle_wait on
    edit $argv
    toggle_wait off
end
