# dcl - List all docker containers
export def dcl [...args] {
    ^docker container ls -a ...$args
}
