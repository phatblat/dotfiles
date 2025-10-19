#!/usr/bin/env fish
function edit \
    --description="Edit using the configured VISUAL editor (TextMate) for GUI terminal sessions or EDITOR for CLI (SSH) sessions."

    if test -z $VISUAL
        eval "$EDITOR '$argv'"
    else
        eval "$VISUAL '$argv'"
    end
end
