# Dependencies:
#   functions: none
#   builtins:  path join
#   externals: ~/scripts/agent-harnesses.py

# Generate shared/native agent harness parity artifacts.
export def --wrapped hg [...args] {
    ^($nu.home-dir | path join "scripts" "agent-harnesses.py") generate ...$args
}
