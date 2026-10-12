# dvr - Remove one or more volumes
export def dvr [...args] {
    ^docker volume rm ...$args
}
