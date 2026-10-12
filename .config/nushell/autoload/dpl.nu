# dpl - View output from docker containers
export def --wrapped dpl [...args] {
    ^docker compose logs --follow ...$args
}
