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
alias xps='ps aux | grep nginx'
alias xtraffic='goaccess -f /usr/local/var/log/nginx/access.log'

# Apache
alias htstatus="ps awx | grep httpd"

