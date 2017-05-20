# Edit the main nginx configuration file.
function xconf
    edit (brew_home)/etc/nginx/**.conf $argv
end
