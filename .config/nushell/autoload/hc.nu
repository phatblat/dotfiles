# Dependencies:
#   functions: none
#   builtins:  path join
#   externals: ~/scripts/agent-harnesses.py

# Validate generated harness parity artifacts.
export def --wrapped hc [...args] {
    ^($nu.home-dir | path join "scripts" "agent-harnesses.py") validate ...$args
}
