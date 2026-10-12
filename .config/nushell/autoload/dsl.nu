# dsl - List docker services
export def --wrapped dsl [...args] {
    ^docker service ls ...$args
}
