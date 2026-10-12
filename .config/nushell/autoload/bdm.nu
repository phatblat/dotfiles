# bdm - Delete local branches which have been merged into the current branch, always preserving master
export def bdm [] {
    ^git branch --merged
    | ^grep -Ev "(^\\*|master)"
    | ^xargs git branch -d
}
