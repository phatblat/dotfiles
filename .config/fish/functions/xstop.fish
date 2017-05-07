# Stops nginx.
function xstop
    nginx -s stop $argv
end
