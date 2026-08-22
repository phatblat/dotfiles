# cmt - Commit with message, or auto-commit dirty files via the OMP commit
# workflow. A single positional argument (no extra flags) that resolves to
# an existing file or directory path within the current git repo is treated
# as a path to scope the auto-commit to (like the no-arg form, but
# restricted to that path) rather than as a commit message.
export def cmt [
    message?: string  # commit message, or a path to auto-commit
    ...args           # additional git commit flags
] {
    if ($message | is-empty) {
        ^omp --print "/git:commit" --model smol --auto-approve
    } else {
        let repo_root = (try { ^git rev-parse --show-toplevel | str trim } catch { null })
        if ($args | is-empty) and ($repo_root != null) and ($message | path exists) {
            let abs_path = ($message | path expand)
            if ($abs_path == $repo_root) or ($abs_path | str starts-with $"($repo_root)/") {
                ^omp --print $"/git:commit only the path: ($abs_path)" --model smol --auto-approve
            } else {
                ^git commit --verbose -m $message ...$args
            }
        } else {
            ^git commit --verbose -m $message ...$args
        }
    }
}
