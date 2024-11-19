function xconf \
        --description='Edit nginx configuration files.'
    pushd (brew_home)/etc/nginx/
    sa
    edit **.conf
end
