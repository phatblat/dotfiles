# Launch Codex without alternate screen mode
export def --wrapped cx [...args] {
    ^codex --no-alt-screen ...$args
}
