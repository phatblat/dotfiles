# Prints function_template.
function function_template --argument-names function_name argname
    if test -z $function_name
        echo "Usage: function_template function_name [argname]"
        return 1
    end

    if test -z $argname
        set argname argname
    end

    echo "\
        function $function_name \
            --description='$function_name' \
        end" \
    | fish_indent --ansi
end
