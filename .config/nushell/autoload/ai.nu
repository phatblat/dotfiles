# ai - Interactively add files to git staging area
export def ai [...args] {
    ^git add --interactive ...$args
}
