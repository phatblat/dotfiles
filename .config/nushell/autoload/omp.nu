# Launch OMP with home-directory sessions allowed and the machine default profile
# from OMP_DEFAULT_PROFILE (no --profile when that variable is empty).
# Caller-supplied --allow-home/--profile always win; neither flag is duplicated.
export def --wrapped omp [...args] {
    mut extra = []
    if not ($args | any {|a| $a == "--allow-home" }) {
        $extra = ($extra | append "--allow-home")
    }
    let profile = ($env.OMP_DEFAULT_PROFILE? | default "" | str trim)
    if ($profile | is-not-empty) and (not ($args | any {|a| $a == "--profile" or ($a | str starts-with "--profile=") })) {
        $extra = ($extra | append ["--profile" $profile])
    }
    ^omp ...$extra ...$args
}
