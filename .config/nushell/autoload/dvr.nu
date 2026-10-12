# dvr - Remove one or more volumes
export def --wrapped dvr [...args] {
    ^docker volume rm ...$args
}
