# Continue the last Codex session (delegates to cx for --no-alt-screen + terminal cleanup)
export def --wrapped cxc [...args] {
    cx resume --last ...$args
}
