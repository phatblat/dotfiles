# dct - Display the running processes of a docker container
export def --wrapped dct [...args] {
    ^docker container top ...$args
}
