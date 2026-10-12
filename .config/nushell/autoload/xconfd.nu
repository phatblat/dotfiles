# xconfd - Quick dir navigation to nginx config dir
export def --env xconfd [] {
    let bh = (^brew --prefix | str trim)
    cd $"($bh)/etc/nginx"
}
