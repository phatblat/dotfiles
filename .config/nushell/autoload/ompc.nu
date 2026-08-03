# Continue the most recent OMP session.
export def --wrapped ompc [...args] {
    ^omp --allow-home --continue ...$args
}
