# ai - Interactively add files to git staging area
export def --wrapped ai [...args] {
    ^git add --interactive ...$args
}
