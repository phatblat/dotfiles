# Options (ls style):
# - `-C` `--column`     Force multi-column output; this is the default when output is to a terminal.
# - `-l `--long`     List in long format.
function funky \
    --description='Searches for functions with the given string in their definition.' \
    --argument-names query option

    if test -z $query
        echo Usage: funky $query
        return 1
    end

    set -l results (grep $query ~/.config/fish/functions/*.fish)
    set -l funcs

    for line in $results
        set -l path (string split ' ' $line)[1]
        # echo path: $path

        set -l file_name (string split '/' $path)[-1]
        # echo file_name: $file_name

        set -l func_name (string replace --regex '\.fish.*' '' $file_name)
        # echo func_name: $func_name

        # Add function to list if not already present
        if not contains $func_name $funcs
            set funcs $funcs $func_name
        end
    end

    if test -n "$option"
        switch $option
            case -C --column
                echo $funcs\n | column -x
                return
            case -l --long
                echo $funcs\n
                return
            case '*'
                echo $funcs\n | column -x
                return
        end
    end

    if test -z $funcs
        return 1
    end

    list $funcs | column -x
end
