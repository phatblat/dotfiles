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

    if test -z "$char_name"
        set -l prev_emoji ""
        for i in (seq (count $names))
            if test $prev_emoji != $all_emoji[$i]
                if test -n "$prev_emoji"
                    # Line feed before all but the first line of output
                    echo
                end
                # Line feed when emoji changes
                echo -n "  "$all_emoji[$i]"  "
            end
            echo -n " "$names[$i]
            set prev_emoji $all_emoji[$i]
        end
        echo
        return
    end

    # Fetch character
    set -l emoji (emoji_map $char_name ^/dev/null)

    if test -n "$emoji"
        # Print and copy
        echo $emoji
        echo $emoji"  " | pbcopy
        return
    end

    error "Unknown emoji: $char_name"
    return 2
end
