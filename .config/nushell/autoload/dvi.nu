# dvi - Display detailed information on one or more docker volumes
export def --wrapped dvi [...args] {
    ^docker volume inspect ...$args
}
