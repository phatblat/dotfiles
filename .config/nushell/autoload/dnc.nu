# dnc - Create a docker network
export def --wrapped dnc [...args] {
    ^docker network create ...$args
}
