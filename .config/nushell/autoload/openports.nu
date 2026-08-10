# Dependencies:
#   functions: none
#   builtins:  lines where str contains
#   externals: lsof

# List open listening ports via lsof
#
# -n and -P skip reverse-DNS and port-name lookups. Without them lsof blocks on
# DNS for every connection: measured 10256ms vs 155ms, same LISTEN rows.
export def openports [] {
    ^lsof -nP -i | lines | where { |line| $line | str contains "LISTEN" }
}
