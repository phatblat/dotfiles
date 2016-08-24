#-------------------------------------------------------------------------------
#
# www/nginx.zsh
# Nginx command-line aliases
#
#-------------------------------------------------------------------------------

# nginx
alias xconf='vi /usr/local/etc/nginx/nginx.conf'
alias xconfd='cd /usr/local/etc/nginx'
alias xstart='sudo nginx'
alias xreload='sudo nginx -s reload'
alias xstop='sudo nginx -s stop'
alias xstatus='ps aux | grep nginx'
alias xps='xstatus'

# Log review
alias xtraffic='goaccess --time-format=%T --date-format=%d/%b/%Y --log-format='%h %^[%d:%t %^] \"%r\" %s %b \"%R\" \"%u\"' -f /usr/local/var/log/nginx/access.log'

alias xaccess='less /usr/local/var/log/nginx/access.log'
alias xerror='less /usr/local/var/log/nginx/error.log'
alias faccess='tail -f /usr/local/var/log/nginx/access.log'
alias ferror='tail -f /usr/local/var/log/nginx/error.log'

function firewall_allow_nginx {
  nginx_path=`brew list nginx | head -n 1`
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add ${nginx_path}
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp ${nginx_path}
}

# Apache
alias htstatus="ps awx | grep httpd"
