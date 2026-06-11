# Dependencies:
#   functions: none
#   builtins:  none
#   externals: claude

# Resume a Claude Code session (claude --dangerously-skip-permissions --resume)
export def --wrapped ccr [...rest] {
    ^claude --dangerously-skip-permissions --resume ...$rest
}
