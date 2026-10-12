# dii - Display detailed information on one or more docker images
export def dii [...args] {
    ^docker image inspect ...$args
}
