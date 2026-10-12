# xtraffic - Display HTTP traffic stats using goaccess
export def xtraffic [...args] {
    let bh = (brew_home) | str trim
    ^goaccess --time-format=%T --date-format=%d/%b/%Y --log-format='%h %^[%d:%t %^] "%r" %s %b "%R" "%u"' -f $"($bh)/var/log/nginx/access.log" ...$args
}
