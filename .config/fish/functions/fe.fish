# Edit a function.
function fe --argument-names function_name
    if not functions --query $function_name
        yn $function_name" doesn't exist. Create?"
            and fn $function_name
        return
    end

    toggle_wait on

    funced $function_name

    toggle_wait off
end
