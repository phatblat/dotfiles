function path \
    --description='path' \
    --argument-names command directory

    switch $command
        case list
            # Pretty prints the current paths
            echo fish_user_paths
            list $fish_user_paths
            echo
            echo PATH
            list $PATH
        case add
            if test -z "$directory"
                error "Usage: path add <directory>"
                return 1
            else if test -d "$directory"
                # https://fishshell.com/docs/current/cmds/fish_add_path.html?highlight=fish_add_path
                fish_add_path --prepend "$directory"
            else
                error "Directory not found: $directory"
                return 2
            end
        case '*' show
            # Prints the current paths
            echo fish_user_paths
            string join \n -- $fish_user_paths
            echo
            echo PATH
            string join \n -- $PATH
    end
end
