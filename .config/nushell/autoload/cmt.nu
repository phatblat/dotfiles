source ~/.config/nushell/autoload/omp.nu

# cmt - Open OMP commit workflow with optional path scoping
export def cmt [
    path?: string  # optional path to scope the commit to
    ...args        # additional arguments
] {
    if ($path | is-empty) {
        omp --allow-home --print /git:commit --model smol --auto-approve
    } else {
        omp --allow-home --print $"/git:commit only the path: ($path) — exactly one commit for that path alone; do not group, stage, or mention other dirty files; no confirmation needed" --model smol --auto-approve
    }
}
