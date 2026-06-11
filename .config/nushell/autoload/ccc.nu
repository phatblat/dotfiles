# Dependencies:
#   functions: none
#   builtins:  none
#   externals: claude

# Continue a Claude Code session (claude --dangerously-skip-permissions --continue)
export def --wrapped ccc [...rest] {
    ^claude --dangerously-skip-permissions --continue ...$rest
}
