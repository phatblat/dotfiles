# xreload - Reload nginx configuration
export def --wrapped xreload [...args] {
    ^sudo nginx -s reload ...$args
}
