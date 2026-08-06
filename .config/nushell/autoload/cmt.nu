export def cmt [
    message?: string  # commit message
    ...args           # additional git commit flags
] {
    if ($message | is-empty) {
        ^omp "/git:commit"
    } else {
        ^git commit --verbose -m $message ...$args
    }
}
