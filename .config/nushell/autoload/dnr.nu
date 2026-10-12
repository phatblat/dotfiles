# dnr - Remove one or more docker networks
export def --wrapped dnr [...args] {
    ^docker network rm ...$args
}
