function 📦__apt \
    --description='Updates APM packages Linux.'

    echo "📦  Advanced Package Manager"
    echo

    set -l packages \
        apt-file \
        cpu-checker

    set -l uninstall

    set -l installed (apt-cache pkgnames)

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
    echo "apt-file update"
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
    if test -n "$not_installed"
        for package in $not_installed
            echo "Installing $package"
            apt-get install $package
        end
    end
end
