# error - Prints args to stderr
export def --wrapped error [...args: string] {
    print --stderr ($args | str join " ")
}
