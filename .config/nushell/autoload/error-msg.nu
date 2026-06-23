# Dependencies:
#   functions: none
#   builtins:  print
#   externals: none

# Print all arguments to stderr
export def error-msg [...args: string] {
    print --stderr ($args | str join " ")
}
