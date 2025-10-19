#!/usr/bin/env fish
function findup \
    --description='Recursively searches up the directory tree looking for files.' \
    --argument-names pattern

    if test -z $pattern
        error "Usage: findup pattern"
        return 1
    end

    # Start in the current directory
    set -l path (realpath .)

    # Stop at the root directory
    while not string match --quiet / $path
        # Print full path if file found
        stat -qf '%N' $path/$pattern

        # Recurse using parent directory
        set path (realpath (dirname $path))
    end
end
