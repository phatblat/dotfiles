# xconf - Edit nginx configuration files
export def --env xconf [] {
    let bh = (brew_home) | str trim
    cd $"($bh)/etc/nginx/"
    sa
    edit ...(glob "**/*.conf")
}
