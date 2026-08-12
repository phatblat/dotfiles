# stdiff - Show diff of a git stash
# Usage: stdiff [n]  (defaults to 0, the most recent stash)
export def stdiff [...args] {
    let n = if ($args | is-empty) { 0 } else { $args.0 }
    let rest = if ($args | is-empty) { [] } else { $args | skip 1 }
    let stash = $"stash@{($n)}"
    ^git --no-pager diff ($stash + "^.." + $stash) ...$rest
}
