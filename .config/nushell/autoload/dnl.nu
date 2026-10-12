# dnl - List docker networks
export def --wrapped dnl [...args] {
    ^docker network ls ...$args
}
