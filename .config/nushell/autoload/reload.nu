# reload - Reload a zsh autoload function by name
# Nushell has no per-function autoload mechanism; re-exec the shell to pick up
# changes to any autoload file. The function-name argument is accepted for
# compatibility with the zsh version but is otherwise ignored.
export def reload [name: string = ""] {
    exec nu
}
