# Reload nginx configuration.
function xreload
    sudo nginx -s reload $argv
end
