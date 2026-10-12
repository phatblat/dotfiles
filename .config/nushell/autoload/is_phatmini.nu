# is_phatmini - Tests whether the current computer is phatmini
export def is_phatmini [] {
    (^hostname | str trim | str contains "phatmini")
}
