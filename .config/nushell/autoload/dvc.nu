# dvc - Create a docker volume
export def --wrapped dvc [...args] {
    ^docker volume create ...$args
}
