# xtraffic - Display HTTP traffic stats using goaccess
export def --wrapped xtraffic [...args] {
    let bh = (^brew --prefix | str trim)
    ^goaccess --time-format=%T --date-format=%d/%b/%Y --log-format='%h %^[%d:%t %^] "%r" %s %b "%R" "%u"' -f $"($bh)/var/log/nginx/access.log" ...$args
}
