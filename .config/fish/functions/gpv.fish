function gpv \
    --description='Quick nav to GooglePlatformVersions dir.'

    set -l gpv_dir ~/dev/GooglePlatformVersions

    if not test -d $gpv_dir
        nav ~/dev
        clone git@github.com:phatblat/GooglePlatformVersions.git
    else
        nav $gpv_dir
        pull
    end

    lg10
end
