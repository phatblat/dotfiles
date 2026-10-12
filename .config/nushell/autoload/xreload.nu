# xreload - Reload nginx configuration
export def xreload [...args] {
    ^sudo nginx -s reload ...$args
}
