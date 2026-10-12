# dni - Display detailed information on one or more docker networks
export def --wrapped dni [...args] {
    ^docker network inspect ...$args
}
