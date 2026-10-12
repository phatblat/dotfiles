# dss - Scale one or multiple replicated docker services
export def dss [...args] {
    ^docker service scale ...$args
}
