# Dependencies:
#   functions: cc
#   builtins:  none
#   externals: none

# Resume a Claude Code session (claude --dangerously-skip-permissions --resume)
export def --wrapped ccr [...rest] {
    cc --resume ...$rest
}
