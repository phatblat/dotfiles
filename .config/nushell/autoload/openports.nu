# Dependencies:
#   functions: none
#   builtins:  lines where str contains
#   externals: lsof

# List open listening ports via lsof -i
export def openports [] {
    ^lsof -i | lines | where { |line| $line | str contains "LISTEN" }
}
