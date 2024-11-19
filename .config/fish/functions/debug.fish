function debug \
    --description='Prints args only when debug env var is set.'

    if test -n "$debug"
        echo "DEBUG:" $argv
    end
end
