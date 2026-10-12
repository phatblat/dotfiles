# dcstart - Start one or more stopped docker containers
export def --wrapped dcstart [...args] {
    ^docker container start ...$args
}
