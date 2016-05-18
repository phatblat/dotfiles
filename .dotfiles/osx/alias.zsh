#-------------------------------------------------------------------------------
#
# osx/alias.zsh
# OS X specific command-line aliases
#
#-------------------------------------------------------------------------------

alias firewall='/usr/libexec/ApplicationFirewall/socketfilterfw'
alias firewall_toggle='firewall --setglobalstate off && \
  firewall --setglobalstate on'


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
