# dnl - List docker networks
export def dnl [...args] {
    ^docker network ls ...$args
}
