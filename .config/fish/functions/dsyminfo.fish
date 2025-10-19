#!/usr/bin/env fish
# Displays information for a Dwarf symbol file.
function dsyminfo --wraps dwarfdump --argument-names file
    if test -z "$file"
        echo "Usage: dsyminfo path/to/dsym"
        return 1
    end

    dwarfdump -u $file $argv
end
