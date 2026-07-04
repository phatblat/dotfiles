# Resume a Codex session (delegates to cx for --no-alt-screen + terminal cleanup)
export def --wrapped cxr [...args] {
    cx resume ...$args
}
