# dps - List docker containers
export def --wrapped dps [...args] {
    ^docker ps ...$args
}
