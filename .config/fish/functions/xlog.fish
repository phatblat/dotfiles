function xlog \
        --description='Quick nav to nginx log dir' \
        --argument-names subdir

    nav (brew_home)/var/log/nginx/$subdir
end
