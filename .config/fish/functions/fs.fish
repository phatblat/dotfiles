# Save a function to user's autoload dir.
function fs --argument-names function_name
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
        # echo comments:\n$comment_lines
    end

    funcsave $function_name

    if test -n $comment_lines
        # Read in the new function definition
        set -l new_contents (cat $dest_file)

        # Wipe out the file with the original comments
        echo -n $comment_lines\n >$dest_file

        # Filter the new content to fix indentation
        for line in $new_contents
            set -l first_char (string sub --length 1 $line)
            set -l all_after_first_char (string sub --start 1 $line)

            if test \t = $first_char
                # Skip the tab on the first line of the function body
                # Somehow the \t takes up 2 chars?
                echo "    "(string sub --start 2 $line) >>$dest_file
            else
                echo $all_after_first_char >>$dest_file
            end
        end
        # echo "Comments restored"
    end

    cat $dest_file
end
