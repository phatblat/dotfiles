source ~/.config/nushell/autoload/omp.nu

# Run OMP with the reflection profile (Reflection's Beam model).
export def --wrapped reflection [...args] {
    omp --profile reflection ...$args
}
