# Reload nginx configuration.
function xreload
    nginx -s reload $argv
end
