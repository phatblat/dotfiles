function mpv \
    --description='Quick nav to MicrosoftPlatformVersions dir.'

    set -l mpv_dir ~/dev/MicrosoftPlatformVersions

    if not test -d $mpv_dir
        nav ~/dev
        clone git@github.com:phatblat/MicrosoftPlatformVersions.git
    else
        nav $mpv_dir
        pull
    end

    lg10
end
