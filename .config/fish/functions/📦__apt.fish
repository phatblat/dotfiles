function 📦__apt \
    --description='Updates APM packages Linux.'

    echo "📦  Advanced Package Manager"
    echo
    apt list

    set -l packages \
        cpu-checker

    set -l uninstall

    set -l installed
    set -l installed_with_version (apt list)
    for package in $installed_with_version
        # Strip off version numbers and arxhitecture
        # zzuf/eoan 0.15-1 amd64
        # zzuf/eoan 0.15-1 i386
        set -l bare_package (string replace --regex "/.*" "" -- $package)

        # Dedupe
        if not contains $package $installed
            set installed $installed $bare_package
        end
    end

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
        apt uninstall $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update installed packages
    echo "apt update"
    sudo apt update
    sudo apt upgrade

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
            apt install $package
        end
    end
end
