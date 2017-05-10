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
        echo comments:\n$comment_lines
    end

    funcsave $function_name

    if test -n $comment_lines
        set -l new_contents $comment_lines (cat $dest_file)
        echo $new_contents\n >$dest_file
        echo "Comments restored"
    end
end
