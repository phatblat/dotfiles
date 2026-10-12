# error - Prints args to stderr
export def error [...args: string] {
    print --stderr ($args | str join " ")
}
