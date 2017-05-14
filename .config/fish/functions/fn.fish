# Create a new function.
function fn --argument function_name
    set -l file ~/.config/fish/functions/$function_name.fish

    if functions --query $function_name; and not test -e $file
        yn "Function "$function_name" already exists. Edit?"
        and fe $function_name
        return
    end

    # Function template
    echo "# $function_name
function $function_name --argument-names arg1
    if test -z \$arg1
        echo \"Usage: $function_name arg1\"
        return 1
    end
    switch \$arg1
        case on ON On
        case off OFF Off
        case '*'
    end
end"\
>$file

    editw $file
    fish_indent --write $file
    reload $function_name

    echo $function_name function created.
end
