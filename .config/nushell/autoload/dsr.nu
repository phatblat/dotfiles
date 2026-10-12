# dsr - Remove one or more docker services
export def --wrapped dsr [...args] {
    ^docker service rm ...$args
}
