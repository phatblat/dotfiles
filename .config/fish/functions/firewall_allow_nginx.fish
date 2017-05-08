# 
function firewall_allow_nginx
      nginx_path=`brew list nginx | head -n 1`
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add ${nginx_path}
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp ${nginx_path} $argv
end
