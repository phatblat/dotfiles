export def cmt [
    message: string  # commit message
    ...args          # additional git commit flags
] {
    ^git commit --verbose -m $message ...$args
}
