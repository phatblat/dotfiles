# dct - Display the running processes of a docker container
export def dct [...args] {
    ^docker container top ...$args
}
