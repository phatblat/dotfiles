# dcstop - Stop one or more running docker containers
export def dcstop [...args] {
    ^docker container stop ...$args
}
