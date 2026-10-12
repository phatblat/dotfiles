# dcl - List all docker containers
export def --wrapped dcl [...args] {
    ^docker container ls -a ...$args
}
