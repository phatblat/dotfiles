function apv \
    --description='Quick nav to ApplePlatformVersions dir.'

    set -l apv_dir ~/dev/ApplePlatformVersions

    if not test -d $apv_dir
        nav ~/dev
        clone git@github.com:phatblat/ApplePlatformVersions.git
    else
        nav $apv_dir
        pull
    end

    lg10
end
