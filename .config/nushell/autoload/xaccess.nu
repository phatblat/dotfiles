# xaccess - Read nginx access log
export def xaccess [...args] {
    let bh = (brew_home) | str trim
    ^less $"($bh)/var/log/nginx/access.log" ...$args
}
