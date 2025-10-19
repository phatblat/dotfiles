#!/usr/bin/env fish
function psgrep \
    --description 'Wrapper for ps which isolates processes containing a given string.' \
    --argument-names process_name

    if test -z "$process_name"
        echo "Usage: psgrep process_name"
        return 1
    end

    ps aux | grep --invert-match 'grep' | grep $process_name
end
