# dpp - List docker containers managed by docker compose
export def dpp [...args] {
    ^docker compose ps ...$args
}
