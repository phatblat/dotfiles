#!/usr/bin/env fish
# Dictionary/Map Data Structure for emoji.
#
# Replicating a simple map in fish. A *_map function accepting 0-Many key names and returning various values. Values are printed to stdout.
#
# - No args: Prints a JSON-encoded dictionary/map of the contained keys and their mappings.
# - No contents Prints an empty JSON dictionary.
# - One arg: Prints the value for the given key.
# - No value for key: Return error status code and nothing prints.
# - Many args: Print the value found for each key.
# - Many args, some missing: Return error status code equal to the number of missing values, number of printed values will be eqal to the number of found values.
function emoji_map
    set -l data_file ~/.config/fish/data/emoji.json
    set -l names (jq --raw-output 'keys_unsorted' $data_file \
        | grep '^ .*' \
        | string replace --regex '  "(\\w+)",?' '$1' \
    )

    if test -z "$argv"
        cat $data_file
        return
    end

    set -l missing_keys

    # One or more key args
    while test (count $argv) -gt 0
        set -l key $argv[1]

        if contains -- $key $names
            # Found a valid key
            jq --raw-output "."$key $data_file
        else
            set missing_keys $missing_keys $key
        end

        # Erase the key just used
        set --erase argv[1]
    end

    if test (count $missing_keys) -eq 0
        # Found everything
        return
    else
        error "No value found for keys: $missing_keys"
        return (count $missing_keys)
    end

    error "Unknown emoji: $char_name"
    return 99
end
