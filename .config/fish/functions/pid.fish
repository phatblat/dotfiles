function pid \
    --description 'Wrapper for ps which isolates processes containing a given string.' \
    --argument-names process_name

    if test -z "$process_name"
        echo "Usage: pid process_name"
        return 1
    end

    psgrep $process_name | awk '{print $2}'
end
