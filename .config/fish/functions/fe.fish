# Edit a function.
function fe --argument-names function_name
    set -l file ~/.config/fish/functions/$function_name.fish

    if not functions --query $function_name; and not test -e $file
        yn "Function "$function_name" does not exist. Create?"
        and fn $function_name
        return
    end

    toggle_wait on

    if test -e $file
        # Edit an autoloaded function
        edit $file
        and reload $function_name
    else
        # Edit a builtin function, save to autoload
        funced $function_name
        and funcsave $function_name
    end

    toggle_wait off
end
