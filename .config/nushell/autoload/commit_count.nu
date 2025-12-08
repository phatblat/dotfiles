# Count commits by date for a branch over a time period
def commit_count [
    days?: int       # Number of days to look back (defaults to 7)
    branch?: string  # Branch name (defaults to current branch)
] {
    let actual_days = if ($days | is-empty) { 7 } else { $days }

    let actual_branch = if ($branch | is-empty) {
        git rev-parse --abbrev-ref HEAD | str trim
    } else {
        $branch
    }

    git log $actual_branch $"--since=($actual_days) days ago" --pretty=format:"%ad" --date=short
    | lines
    | sort
    | uniq --count
    | sort-by count --reverse
}
