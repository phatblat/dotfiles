# Delete a function
function fd --argument function_name
	if not functions --query $function_name
        echo "Function "$function_name" does not exist."
        return 1
    end

    set -l file ~/.config/fish/functions/$function_name.fish

    functions --erase $function_name
    # Delete file if it exists
    and not test -e $file; or rm -f $file
    and echo "Function "$function_name" deleted."
end
