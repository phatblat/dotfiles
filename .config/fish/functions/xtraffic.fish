
# null
function xtraffic
    goaccess --time-format=%T --date-format=%d/%b/%Y --log-format='%h %^[%d:%t %^] \"%r\" %s %b \"%R\" \"%u\"' -f /usr/local/var/log/nginx/access.log
end
