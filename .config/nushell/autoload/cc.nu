# Wrapper to invoke Claude Code with default configuration
export def cc [...args] {
    ^claude --dangerously-skip-permissions ...$args
}
