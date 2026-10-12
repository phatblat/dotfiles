# dcstop - Stop one or more running docker containers
export def --wrapped dcstop [...args] {
    ^docker container stop ...$args
}
