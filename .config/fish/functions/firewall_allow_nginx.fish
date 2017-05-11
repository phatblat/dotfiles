# Configures the firewall to allow incoming connections to the current nginx version.
function firewall_allow_nginx
    firewalladd (brew list nginx | head -n 1)
end
