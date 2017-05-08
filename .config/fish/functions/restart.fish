# 
function restart
      if [[ "$(fdesetup isactive)" = "true" ]]; then
    # FileVault authenticated restart
    sudo fdesetup authrestart -verbose
  else
    # Normal restart
    sudo shutdown -r now "Rebooting now"
  fi $argv
end
