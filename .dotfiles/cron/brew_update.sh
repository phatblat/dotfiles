#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# cron/brew_update.sh
#
#-------------------------------------------------------------------------------

. $HOME/.dotfiles/cron/cron.env

brew_path=`which brew`
$brew_path update > /dev/null && $brew_path upgrade --all > /dev/null

# firewall_allow_nginx
nginx_path=`brew list nginx | head -n 1`
# sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add ${nginx_path}
# sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp ${nginx_path}
