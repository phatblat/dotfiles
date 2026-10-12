# dsl - List docker services
export def dsl [...args] {
    ^docker service ls ...$args
}
