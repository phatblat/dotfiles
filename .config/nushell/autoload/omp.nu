# Launch OMP with home-directory sessions allowed. Profile selection is
# env-based: omp reads OMP_PROFILE itself (set in ~/.env), and an explicit
# profile flag on the command line overrides that variable.
export def --wrapped omp [...args] {
    if ($args | any {|a| $a == "--allow-home" }) {
        ^omp ...$args
    } else {
        ^omp --allow-home ...$args
    }
}
