# xtest - Validate nginx config
export def xtest [...args] {
    ^sudo nginx -t ...$args
}
