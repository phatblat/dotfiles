# dpp - List docker containers managed by docker compose
export def --wrapped dpp [...args] {
    ^docker compose ps ...$args
}
