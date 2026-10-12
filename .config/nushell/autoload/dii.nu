# dii - Display detailed information on one or more docker images
export def --wrapped dii [...args] {
    ^docker image inspect ...$args
}
