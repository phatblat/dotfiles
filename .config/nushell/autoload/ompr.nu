source ~/.config/nushell/autoload/omp.nu

# Browse and resume an OMP session.
export def --wrapped ompr [...args] {
    omp --resume ...$args
}
