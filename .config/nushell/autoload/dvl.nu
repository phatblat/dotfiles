# dvl - List docker volumes
export def --wrapped dvl [...args] {
    ^docker volume ls ...$args
}
