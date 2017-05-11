# Edit a function.
function fe --argument-names function_name
    if not functions --query $function_name
        yn $function_name" doesn't exist. Create?"
            and fn $function_name
        return
    end

    set old_VISUAL $VISUAL
    set VISUAL $VISUAL" -w"

    funced $function_name

    set VISUAL $old_VISUAL
end
