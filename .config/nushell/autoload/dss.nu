# dss - Scale one or multiple replicated docker services
export def --wrapped dss [...args] {
    ^docker service scale ...$args
}
