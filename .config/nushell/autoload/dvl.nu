# dvl - List docker volumes
export def dvl [...args] {
    ^docker volume ls ...$args
}
