# dpl - View output from docker containers
export def dpl [...args] {
    ^docker compose logs --follow ...$args
}
