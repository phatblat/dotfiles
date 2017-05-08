# 
function allow_all_nginx
      local firewall='/usr/libexec/ApplicationFirewall/socketfilterfw'
  local base_path="$(brew --prefix)/Cellar/nginx"
  local versions=$(ls -1 $base_path)

  for version in $versions; do
    echo $version
    sudo $firewall --add $base_path/$version/bin/nginx
    sudo $firewall --unblockapp $base_path/$version/bin/nginx
  done $argv
end
