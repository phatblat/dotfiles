# Delete a function
function fd --argument function_name
    set -l file ~/.config/fish/functions/$function_name.fish

    if not functions --query $function_name; and not test -e $file
        echo "Function "$function_name" does not exist."
        return 1
    end

    functions --erase $function_name
    # Delete file if it exists
    and not test -e $file; or rm -f $file
    and echo "Function "$function_name" deleted."
end
