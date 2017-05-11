# Create a new function.
function fn --argument function_name
    if functions --query $function_name
        yn $function_name" already exists. Edit?"
        and fe $function_name
        return
    end

    set -l file ~/.config/fish/functions/$function_name.fish

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
    fish_indent $file

    echo $function_name function created.
end
