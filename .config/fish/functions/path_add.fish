function path_add \
    --description 'Path manipulation. Subcommands: show, list, add' \
    --argument-names directory

    if test -z "$directory"
        error "Usage: path_add <directory>"
        return 1
    else if test -d "$directory"
        # https://fishshell.com/docs/current/cmds/fish_add_path.html?highlight=fish_add_path
        fish_add_path --prepend "$directory"
    else
        error "Directory not found: $directory"
        return 2
    end
end
