# xstop - Stops nginx
export def xstop [...args] {
    ^sudo nginx -s stop ...$args
}
