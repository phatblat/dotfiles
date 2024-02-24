function bak \
    --description 'Backs up a file by appending .bak extension. When run on a file that already has .bak, the extension is removed.' \
    --argument-names file
    if not test -e $file
        echo "🤷🏻‍♂️  '$file' does not exist"
        return 1
    end

    # Strip off trailing slash from dir autocompletion
    set -l pattern '\/$'
    if string match --quiet --regex $pattern $file
        set file (string replace --regex $pattern '' $file)
    end

    set -l components (string split "." -- $file)

    if test $components[-1] = bak
        # Remove the .bak extension
        set new_name (string join "." $components[1..-2])
        mv $file $new_name
        echo "🚚  Renamed to '$new_name'"
    else
        # Append a .bak extension
        mv $file $file.bak
        echo "🚚  Renamed to '$file.bak'"
    end
end
