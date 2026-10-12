# xconfd - Quick dir navigation to nginx config dir
export def --env xconfd [] {
    let bh = (brew_home) | str trim
    cd $"($bh)/etc/nginx"
}
