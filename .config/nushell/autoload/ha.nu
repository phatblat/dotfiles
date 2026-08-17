# Dependencies:
#   functions: none
#   builtins:  path join
#   externals: ~/scripts/agent-harnesses.py

# Audit installed harness versions and parity gaps.
export def --wrapped ha [...args] {
    ^($nu.home-dir | path join "scripts" "agent-harnesses.py") audit ...$args
}
