# Backs up a file by appending .bak extension. When run on a file
# that already has .bak, the extension is removed.
function bak --argument-names file
    if not test -e $file
        echo "'$file' does not exist"
        return 1
    end

    set -l components (string split "." -- $file)

    if test $components[-1] = "bak"
        # Remove the .bak extension
        set new_name (string join "." $components[1..-2])
        mv $file $new_name
        echo "Renamed to '$new_name'"
    else
        # Append a .bak extension
        mv $file $file.bak
        echo "Renamed to '$file.bak'"
    end
end
