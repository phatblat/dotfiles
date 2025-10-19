#!/usr/bin/env fish
function 📦_apt \
    --description='Updates APM packages Linux.'

    echo "📦 Advanced Package Manager"
    echo

    set -l packages \
        apt-file \
        bridge-utils \
        build-essential \
        cpu-checker \
        clang \
        libcurl3 \
        libicu-dev \
        liblzma-dev \
        libncurses5 \
        libpam-u2f \
        libpython2.7 \
        libpython2.7-dev \
        libtinfo5 \
        libvirt-clients \
        libvirt-daemon-system \
        patch \
        ruby-dev \
        qemu-kvm \
        trash-cli \
        virt-manager \
        zlib1g-dev
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
