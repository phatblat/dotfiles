function function_template \
    --description='Prints function_template' \
    --argument-names function_name argname

    if test -z $function_name
        echo "Usage: function_template function_name [argname]"
        return 1
    end

    if test -z $argname
        set argname argname
    end

    printf "function $function_name \\
    --description='$function_name' \\
    --argument-names $argname

    if test -z \$$argname
        echo 'Usage: $function_name [$argname]'
        return 1
    end


end
" \
        | cat

    # echo $contents
    # | fish_indent --ansi
end
