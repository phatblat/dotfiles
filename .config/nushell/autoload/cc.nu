# Dependencies:
#   functions: none
#   builtins:  none
#   externals: claude

# Wrapper to invoke Claude Code with default configuration
export def --wrapped cc [...args] {
    ^claude --dangerously-skip-permissions ...$args
}
