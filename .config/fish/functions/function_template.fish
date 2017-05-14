# Prints function_template.
function function_template --argument-names function_name
    if test -z $function_name
        echo "Usage: function_template function_name"
        return 1
    end

    echo "# $function_name
        function $function_name --argument-names arg1
            if test -z \"\$arg1\"
                echo \"Usage: $function_name arg1\"
                return 1
            end
            switch \$arg1
                case on ON On
                case off OFF Off
                case '*'
            end
        end" \
        | fish_indent --ansi
end
