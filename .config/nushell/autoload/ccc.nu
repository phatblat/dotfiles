# Dependencies:
#   functions: cc
#   builtins:  none
#   externals: none

# Continue a Claude Code session (claude --dangerously-skip-permissions --continue)
export def --wrapped ccc [...rest] {
    cc --continue ...$rest
}
