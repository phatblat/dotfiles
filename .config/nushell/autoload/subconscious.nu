source ~/.config/nushell/autoload/omp.nu

# Run OMP with the subconscious profile (Subconscious long-context inference).
export def --wrapped subconscious [...args] {
    omp --profile subconscious ...$args
}
