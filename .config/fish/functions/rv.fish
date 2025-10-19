#!/usr/bin/env fish
# List git remote details.
function rv
    # Example input:
    # origin    git@github.com:phatblat/mas.git (fetch)
    # origin    git@github.com:phatblat/mas.git (push)
    # upstream    git@github.com:mas-cli/mas.git (fetch)
    # upstream    git@github.com:mas-cli/mas.git (push)
    set -l input (git remote -v)

    if test -z "$input"
        echo "No remotes are currently defined."
        return 1
    end

    set -l output
    set -l last_remote
    for line in $input
        set -l tokens (list -s $line)
        if test "$last_remote" != $tokens[1]
            # Only add one line for each remote to output
            set output $output (string split \t -- $tokens[1])
            set last_remote $tokens[1]
        end
    end

    # echo output
    list $output | column
end
