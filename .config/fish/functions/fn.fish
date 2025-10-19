#!/usr/bin/env fish
# Create a new function.
function fn --argument function_name
    set -l file ~/.config/fish/functions/$function_name.fish

    # File in autoload may not be loaded (syntax error) and
    # builtin functions won't have files in autoload dir.
    if begin test -e $file
            or functions --query $function_name
        end
        yn "Function "$function_name" already exists. Edit?"
        and fe $function_name
        return
    end

    function_template $function_name >$file

    editw $file
    fish_indent --write $file
    reload $function_name

    if test $status -eq 0
        echo $function_name" function created."
    else
        echo "Error loading $function_name. Please check your syntax in $file"
    end
end
