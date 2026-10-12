# dci - Display detailed information on one or more docker containers
export def dci [...args] {
    ^docker container inspect ...$args
}
