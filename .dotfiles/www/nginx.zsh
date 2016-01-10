#-------------------------------------------------------------------------------
#
# www/nginx.zsh
# Nginx command-line aliases
#
#-------------------------------------------------------------------------------

# nginx
alias xconf='vi /usr/local/etc/nginx/nginx.conf'
alias xstart='sudo nginx'
alias xreload='sudo nginx -s reload'
alias xstop='sudo nginx -s stop'
alias xps='ps aux | grep nginx'

# Apache
alias htstatus="ps awx | grep httpd"

