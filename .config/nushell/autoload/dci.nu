# dci - Display detailed information on one or more docker containers
export def --wrapped dci [...args] {
    ^docker container inspect ...$args
}
