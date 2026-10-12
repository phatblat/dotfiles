# dcr - Remove one or more running docker containers
export def dcr [...args] {
    ^docker container rm --force ...$args
}
