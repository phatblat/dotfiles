#!/usr/bin/env fish
function is_ssh \
    --description="Tests whether the current terminal session is an SSH session"

    test -n "$SSH_CLIENT" -o -n "$SSH_TTY"
end
