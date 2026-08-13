# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Print the symbolic ref for the given treeish
export def ref [...args: string] {
    ^git symbolic-ref ...$args
}
