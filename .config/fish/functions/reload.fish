function reload \
    --description 'Reloads a single function or the entire fish shell.' \
    --wraps functions \
    --argument-names function_name

    set -l file ~/.config/fish/functions/$function_name.fish

    if test -z $function_name
        echo Reloading fish shell
        source ~/.config/fish/config.fish
        return
    else if test -e $file
        echo Reloading fish function $function_name
        source $file
        if test $status -ne 0
            return $status
        end

        # TODO: Show diff of function (memory vs file system)
        # func $function_name
    else
        echo "$function_name does not exist in function autoload dir."
        return 1
    end
end
