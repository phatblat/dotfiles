#-------------------------------------------------------------------------------
#
# macos/alias.zsh
# macOS specific command-line aliases
#
#-------------------------------------------------------------------------------

alias firewall='/usr/libexec/ApplicationFirewall/socketfilterfw'
alias firewall_toggle='firewall --setglobalstate off && \
  firewall --setglobalstate on'

# Convenience admin function to auto-add all versions of nginx to the list of
# apps allowed to receive incoming connections through the firewall.
function allow_all_nginx {
  local firewall='/usr/libexec/ApplicationFirewall/socketfilterfw'
  local base_path="$(brew --prefix)/Cellar/nginx"
  local versions=$(ls -1 $base_path)

  for version in $versions; do
    echo $version
    sudo $firewall --add $base_path/$version/bin/nginx
    sudo $firewall --unblockapp $base_path/$version/bin/nginx
  done
}

#-------------------------------------------------------------------------------
#
# OS X GUI Apps
#
#-------------------------------------------------------------------------------

# Chrome
alias chrome='open -a "Google Chrome" --args --incognito'
alias fixopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; echo "DNS cache flushed"'

# Tower
alias tower='gittower .'

# Dropbox
alias dropboxfinderreset='pluginkit -e use -i com.getdropbox.dropbox.garcon'


#-------------------------------------------------------------------------------
#
# Restart
#
#-------------------------------------------------------------------------------
function restart {
  if [[ "$(fdesetup isactive)" = "true" ]]; then
    # FileVault authenticated restart
    sudo fdesetup authrestart -verbose
  else
    # Normal restart
    sudo shutdown -r now "Rebooting now"
  fi
}
