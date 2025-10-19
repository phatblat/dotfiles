#!/usr/bin/env fish
# Use less to view the XML of a property list file.
function pless --argument-names file
    if test -z "$file"
        echo "Usage: pless file"
        return 1
    end

    plcat $file | less
end
