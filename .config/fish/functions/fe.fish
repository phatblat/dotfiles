# Edit a function.
function fe --argument-names function_name
    set old_VISUAL $VISUAL
    set VISUAL $VISUAL" -w"

    funced $function_name

    set VISUAL $old_VISUAL
end
