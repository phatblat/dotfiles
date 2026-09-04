source ~/.config/nushell/autoload/omp.nu

# Run OMP with the casper profile (Ditto's homegrown AI router).
export def --wrapped casper [...args] {
    omp --profile casper ...$args
}
