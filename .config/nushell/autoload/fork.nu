# Dependencies:
#   functions: none
#   builtins:  none
#   externals: open

# Launch Fork.app on macOS from the terminal
export def --wrapped fork [...rest] {
    ^open -a Fork ...$rest
}
