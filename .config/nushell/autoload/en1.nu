# Dependencies:
#   functions: none
#   builtins:  none
#   externals: ifconfig

# Shows the en1 network interface via ifconfig
export def en1 [] {
    ^ifconfig en1
}
