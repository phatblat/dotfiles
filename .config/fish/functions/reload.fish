# Reloads fish configuration or a single autoloaded function.
function reload --argument-names function_name
    set -l file ~/.config/fish/functions/$function_name.fish

    if test -z $function_name
        source ~/.config/fish/config.fish
        return
    else if test -e $file
        source $file
        if test $status -ne 0
            return $status
        end
        func $function_name
    else
        echo "$function_name does not exist in function autoload dir."
        return 1
    end
end
