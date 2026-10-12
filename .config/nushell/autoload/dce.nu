# dce - Executes a command in a running container
export def dce [...args] {
    ^docker container exec --interactive --tty ...$args
}
