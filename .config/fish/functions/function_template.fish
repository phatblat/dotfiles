function function_template --argument-names function_name argname --description='Prints function_template'
    if test -z $function_name
        echo "Usage: function_template function_name [argname]"
        return 1
    end

    if test -z $argname
        set argname argname
    end

    printf "function $function_name --description='$function_name' \n\
\n\
end" \
    | cat

    # echo $contents
    # | fish_indent --ansi
end
