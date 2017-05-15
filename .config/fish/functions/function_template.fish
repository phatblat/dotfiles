# Prints function_template.
function function_template --argument-names function_name argname
    if test -z $function_name
        echo "Usage: function_template function_name [argname]"
        return 1
    end

    if test -z $argname
        set argname argname
    end

    echo "# $function_name
        function $function_name --argument-names $argname
            if test -z \"\$$argname\" ^/dev/null
                echo \"Usage: $function_name $argname\"
                return 1
            end
            switch \$$argname
                case on ON On
                case off OFF Off
                case '*'
            end
        end" \
        | fish_indent --ansi
end
