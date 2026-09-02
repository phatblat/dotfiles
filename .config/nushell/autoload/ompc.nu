source ~/.config/nushell/autoload/omp.nu

# Continue the most recent OMP session.
export def --wrapped ompc [...args] {
    omp --continue ...$args
}
