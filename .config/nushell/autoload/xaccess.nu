# xaccess - Read nginx access log
export def --wrapped xaccess [...args] {
    let bh = (^brew --prefix | str trim)
    ^less $"($bh)/var/log/nginx/access.log" ...$args
}
