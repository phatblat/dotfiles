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
alias xtraffic='goaccess -f /usr/local/var/log/nginx/access.log'

function firewall_allow_nginx {
  nginx_path=`brew list nginx | head -n 1`
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add ${nginx_path}
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp ${nginx_path}
}

# Apache
alias htstatus="ps awx | grep httpd"
