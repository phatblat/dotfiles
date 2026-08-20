export def cmt [
    message?: string  # commit message
    ...args           # additional git commit flags
] {
    if ($message | is-empty) {
        ^omp --print "/git:commit" --model smol --auto-approve
    } else {
        ^git commit --verbose -m $message ...$args
    }
}
