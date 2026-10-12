# dni - Display detailed information on one or more docker networks
export def dni [...args] {
    ^docker network inspect ...$args
}
