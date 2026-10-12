# cherry-pick - Perform a git cherry-pick
export def --wrapped cherry-pick [...args] {
    ^git cherry-pick ...$args
}
