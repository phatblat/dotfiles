#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# cron/brew_update.sh
#
#-------------------------------------------------------------------------------

# Prime the environment first
# shellcheck source=/Volumes/ThunderBay/Users/phatblat
source "$HOME/.dotfiles/cron/cron.env"

# This can only be run by an admin user
if ! user_is_admin; then
  exit 0
fi

brew_path=$(command -v brew)
$brew_path update > /dev/null && $brew_path upgrade > /dev/null

# firewall_allow_nginx
# nginx_path=`brew list nginx | head -n 1`
# sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add ${nginx_path}
# sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp ${nginx_path}
