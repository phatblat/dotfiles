# dnc - Create a docker network
export def dnc [...args] {
    ^docker network create ...$args
}
