# xlog - Quick nav to nginx log dir
export def --env xlog [subdir?: string = ""] {
    let prefix = (^brew --prefix | str trim)
    cd $"($prefix)/var/log/nginx/($subdir)"
}
