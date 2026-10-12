# dvc - Create a docker volume
export def dvc [...args] {
    ^docker volume create ...$args
}
