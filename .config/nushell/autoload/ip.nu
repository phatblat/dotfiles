# Dependencies:
#   functions: en1
#   builtins:  into string lines where str contains first str trim split row get
#   externals: none

# Show the IPv4 address for the en1 network interface
export def ip [] {
    en1
        | into string
        | lines
        | where { |line| $line | str contains "inet " }
        | first
        | str trim
        | split row " "
        | get 1
}
