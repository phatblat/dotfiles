# dps - List docker containers
export def dps [...args] {
    ^docker ps ...$args
}
