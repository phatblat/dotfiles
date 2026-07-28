# Continue the most recent Pi session.
export def --wrapped pic [...args] {
    ^pi --continue ...$args
}
