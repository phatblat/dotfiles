function fe \
    --description='Edit a function.' \
    --argument-names function_name

    set -l file ~/.config/fish/functions/$function_name.fish

    if begin not test -e $file
            and not functions --query $function_name
        end
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

    if test $status -eq 0
        echo $function_name" function reloaded."
    else
        echo "Error reloading $function_name. Please check your syntax in $file"
    end

    toggle_wait off
end
