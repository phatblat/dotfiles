# xstop - Stops nginx
export def --wrapped xstop [...args] {
    ^sudo nginx -s stop ...$args
}
