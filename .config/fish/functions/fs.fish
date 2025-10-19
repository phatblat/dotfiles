#!/usr/bin/env fish
# Save a function to user's autoload dir.
function fs --argument function_name
    set -l dest_file ~/.config/fish/functions/$function_name.fish
    set -l original_contents
    set -l comment_lines

    if test -e $dest_file
        set original_contents (cat $dest_file)
        for line in $original_contents
            # Collect lines starting with a hash
            if test '#' = (string sub --length 1 $line)
                set comment_lines $comment_lines $line
            end
        end
    end

    funcsave $function_name

    if test -n $comment_lines
        # Read in the new function definition
        set -l new_contents (cat $dest_file)

        # Wipe out the file with the original comments
        echo -n $comment_lines\n >$dest_file
        echo -n $new_contents\n >>$dest_file
    end

    # Fix the funky indentation (tab on first line of body, extra space on all)
    fish_indent --write $dest_file

    cat $dest_file | fish_indent --ansi
end
