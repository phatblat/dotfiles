# Toggle wait
# Given no arguments, switches the state of the editor ($VISUAL) wait flag.
# Otherwise sets it to the given state (on / off)
function toggle_wait \
    --description 'Toggles the editor wait flag.' \
    --argument-names state

    # Empty toggles the current state.
    if test -z $state
        if test -z $VISUAL
            and string match --ignore-case '*'$WAIT_FLAG $EDITOR >/dev/null
            or string match --ignore-case '*'$WAIT_FLAG $VISUAL >/dev/null
            echo -n "Wait mode enabled, disabling"
            set state off
        else
            echo -n "Wait mode disabled, enabling"
            set state on
        end
    end

    switch $state
        case on ON On
            if test -z $VISUAL
                set --global --export EDITOR "$EDITOR_CLI $WAIT_FLAG_CLI"
                or true # FIXME: set command returns non-zero even when sucessful
                echo " (EDITOR: $EDITOR)"
            else
                set --global --export VISUAL "$EDITOR_GUI $WAIT_FLAG_GUI"
                or true
                echo " (VISUAL: $VISUAL)"
            end
        case off OFF Off
            if test -z $VISUAL
                set --global --export EDITOR $EDITOR_CLI
                or true
                echo " (EDITOR: $EDITOR)"
            else
                set --global --export VISUAL $EDITOR_GUI
                or true
                echo " (VISUAL: $VISUAL)"
            end
        case '*'
            echo "Usage: toggle_wait [on|off]"
            return 1
    end
end
