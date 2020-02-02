function 📦__apt \
    --description='Updates APM packages Linux.'

    echo "📦  Advanced Package Manager"
    echo

    set -l packages \
        apt-file \
        cpu-checker
    echo "packages: $packages"

    set -l uninstall

    # set -l installed (apt-cache pkgnames)
    set -l installed (dpkg --get-selections | awk '{print $1}')
    # echo "installed: $installed"

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted packages
    set -l to_uninstall
    for package in $uninstall
        if contains $package $installed
            set to_uninstall $to_uninstall $package
        end
    end
    echo "to_uninstall: $to_uninstall"
    if test -n "$to_uninstall"
        echo "to_uninstall $to_uninstall"
        apt-get remove $to_uninstall
        # apt-get autoremove $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update installed packages
    # echo "apt-file update"
    # apt-file update
    # sudo apt upgrade

    # Install new formula
    set -l not_installed
    for package in $packages
        if not contains $package $installed
            # Include package flags when installing
            set not_installed $not_installed $package
        end
    end
    echo "not_installed: $not_installed"
    if test -n "$not_installed"
        for package in $not_installed
            echo "Installing $package"
            sudo apt-get \
                --assume-yes \
                 --verbose-versions \
                install $package
        end
    end
end
