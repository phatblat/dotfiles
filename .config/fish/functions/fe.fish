# Edit a function.
function fe --argument-names function_name
    set -l file ~/.config/fish/functions/$function_name.fish

    if not functions --query $function_name; and not test -e $file
        yn "Function "$function_name" does not exist. Create?"
        and fn $function_name
        return
    end

    toggle_wait on

    funced $function_name

    toggle_wait off
end
