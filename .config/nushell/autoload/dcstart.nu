# dcstart - Start one or more stopped docker containers
export def dcstart [...args] {
    ^docker container start ...$args
}
