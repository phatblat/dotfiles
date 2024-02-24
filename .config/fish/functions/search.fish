function search \
    --description 'Search for CLI tools through variouss package managers.'

    if is_linux
        echo Snap
        echo -----------------------------------------------------------------
        # Ubuntu snap
        #snap search $argv
        # snapd apt package
        snap find $argv

        echo APT
        echo -----------------------------------------------------------------
        apt search $argv
    else if is_mac
        echo "Mac App Store"
        echo -----------------------------------------------------------------
        mas search $argv
    end

    echo Homebrew
    echo -----------------------------------------------------------------
    brew search $argv
end
