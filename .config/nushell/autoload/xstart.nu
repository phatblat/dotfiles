# xstart - Starts nginx
export def xstart [...args] {
    ^sudo nginx ...$args
    xstatus
}
