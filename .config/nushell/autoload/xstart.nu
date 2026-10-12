# xstart - Starts nginx
export def --wrapped xstart [...args] {
    ^sudo nginx ...$args
    xstatus
}
