# xerror - Read nginx error log
export def xerror [...args] {
    let bh = (brew_home) | str trim
    ^less $"($bh)/var/log/nginx/error.log" ...$args
}
