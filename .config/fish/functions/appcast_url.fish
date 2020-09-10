function appcast_url \
    --argument-names url

    if test -z "$url"
        echo "Usage: appcast_url url"
        return 1
    end

    brew cask _appcast_checkpoint --calculate $url
end
