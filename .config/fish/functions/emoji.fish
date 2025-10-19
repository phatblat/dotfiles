#!/usr/bin/env fish
# Prints an emoji cheat sheet for commit comments.
#
# Taken from:
# - https://gist.github.com/pocotan001/68f96bf86891db316f20
# - https://github.com/atom/atom/blob/master/CONTRIBUTING.md#git-commit-messages
function emoji --argument-names char_name
    set -l names (emoji_map \
        | jq --raw-output 'keys_unsorted' \
        | grep '^ .*' \
        | string replace --regex '  "(\\w+)",?' '$1' \
    )

    set -l all_emoji (emoji_map | jq --raw-output '.[]')
    set -l line
    set -l table

    # Show all emoji when no args given
    if test -z "$char_name"
        set -l prev_emoji ""
        for i in (seq (count $names))
            if test $prev_emoji != $all_emoji[$i]
                set table $table $line
                set line "  "$all_emoji[$i]" "
            end
            set line $line" "$names[$i]
            set prev_emoji $all_emoji[$i]
        end

        list $table | column
        return
    end

    # Iterate over args to find emoji for names
    set -l emoji_found
    set -l emoji_missing
    while test -n "$argv"
        set char_name $argv[1]

        # Fetch character
        set -l emoji (emoji_map $char_name 2>/dev/null)

        if test -n "$emoji"
            set emoji_found $emoji_found $emoji
        else
            set emoji_missing $emoji_missing $char_name
        end

        if test (count $argv) -eq 1
            # Only one arg left, clear out argv
            set --erase argv
        else
            # Pop the processed char name off the arg list
            set argv $argv[2..-1]
        end
    end

    # Print and copy
    echo $emoji_found
    echo -n "$emoji_found " | pbcopy

    if test -n "$emoji_missing"
        error "Unknown emoji: $emoji_missing"
        return 2
    end

    return
end
