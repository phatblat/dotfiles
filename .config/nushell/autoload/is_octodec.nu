# is_octodec - Tests whether the current computer is octodec
export def is_octodec [] {
    (^hostname | str trim | str contains "octodec")
}
