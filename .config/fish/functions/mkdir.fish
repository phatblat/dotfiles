function mkdir \
    --description='Create a directory and set CWD'

    command mkdir -p $argv

    if test $status = 0
        set -l last_arg $argv[(count $argv)]
        switch $last_arg
            case '-*'

            case '*'
                pushd $last_arg
                return
        end
    end
end
