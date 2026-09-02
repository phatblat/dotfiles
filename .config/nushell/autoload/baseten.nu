source ~/.config/nushell/autoload/omp.nu

# Run OMP with the baseten profile.
export def --wrapped baseten [...args] {
    omp --profile baseten ...$args
}
