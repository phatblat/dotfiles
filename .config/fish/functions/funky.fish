# Searches for functions with the given string in their definition.
function funky --argument-names query
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

    echo "Custom, autoloaded functions containing '$query' in their definition:"
    echo $funcs\n | column -x
end
