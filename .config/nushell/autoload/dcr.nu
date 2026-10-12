# dcr - Remove one or more running docker containers
export def --wrapped dcr [...args] {
    ^docker container rm --force ...$args
}
