# dvi - Display detailed information on one or more docker volumes
export def dvi [...args] {
    ^docker volume inspect ...$args
}
