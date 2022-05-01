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
            if test -d "$directory"
                # https://fishshell.com/docs/current/cmds/fish_add_path.html?highlight=fish_add_path
                fish_add_path "$directory"
            end
            path show
        case '*' show
            # Prints the current paths
            echo fish_user_paths
            echo $fish_user_paths
            echo
            echo PATH
            echo $PATH
    end
end
