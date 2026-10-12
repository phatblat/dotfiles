# xerror - Read nginx error log
export def --wrapped xerror [...args] {
    let bh = (^brew --prefix | str trim)
    ^less $"($bh)/var/log/nginx/error.log" ...$args
}
