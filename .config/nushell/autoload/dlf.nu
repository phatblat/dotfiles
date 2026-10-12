# dlf - Alias of dlogs
export def --wrapped dlf [...args] {
    ^docker logs --follow ...$args
}
