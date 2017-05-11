# Toggle wait
# Given no arguments, switches the state of the editor ($VISUAL) wait flag.
# Otherwise sets it to the given state (on / off)
function toggle_wait --argument-names state
    # Empty toggles the current state.
    if test -z $state
        if test -z $VISUAL
            and string match --ignore-case '*'$WAIT_FLAG $EDITOR >/dev/null
            or string match --ignore-case '*'$WAIT_FLAG $VISUAL >/dev/null
            echo "Wait mode enabled, disabling"
            set state off
        else
            echo "Wait mode disabled, enabling"
            set state on
        end
    end

    switch $state
        case on ON On
            if test -z $VISUAL
                set --global --export EDITOR "$EDITOR_CLI $CLI_WAIT_FLAG"
            else
                set --global --export VISUAL "$EDITOR_GUI $GUI_WAIT_FLAG"
            end
        case off OFF Off
            if test -z $VISUAL
                set --global --export EDITOR $EDITOR_CLI
            else
                set --global --export VISUAL $EDITOR_GUI
            end
        case '*'
            echo "Usage: toggle_wait [on|off]"
            return 1
    end

    # echo EDITOR: $EDITOR
    # echo VISUAL: $VISUAL
end
