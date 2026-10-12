# xcbschemes - Displays schemes for an Xcode project
export def xcbschemes [] {
    ^xcblist
    | ^grep "Schemes:" -A 10
    | ^tail -n +2
    | ^sed -e 's/^[ \t]*//'
}
