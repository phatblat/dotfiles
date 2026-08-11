export def stdiff [...args] {
    let stash = if ($args | is-empty) { "stash@{0}" } else { $args.0 }
    let rest = if ($args | is-empty) { [] } else { $args | skip 1 }
    ^git --no-pager diff ($stash + "^.." + $stash) ...$rest
}
