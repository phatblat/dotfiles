# xtest - Validate nginx config
export def --wrapped xtest [...args] {
    ^sudo nginx -t ...$args
}
