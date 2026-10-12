# xconf - Edit nginx configuration files
export def --env xconf [] {
    let bh = (^brew --prefix | str trim)
    cd $"($bh)/etc/nginx/"
    sa
    edit ...(glob "**/*.conf")
}
