# dsr - Remove one or more docker services
export def dsr [...args] {
    ^docker service rm ...$args
}
