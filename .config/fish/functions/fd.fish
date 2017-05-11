# Delete a function
function fd --argument function_name
	if not functions --query $function_name
        echo "Function "$function_name" does not exist."
        return 1
    end

    functions --erase $function_name
        and echo "Function "$function_name" deleted."
end
