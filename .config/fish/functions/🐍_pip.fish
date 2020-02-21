# https://pip.pypa.io/en/stable/
# Python Package Index (PyPI) https://pypi.python.org/pypi
#
# Installs Powerline for Vim
# https://powerline.readthedocs.io/en/latest/
#
# Sequencing
# - After: brew (installed with python)
function 🐍_pip \
    --description='Manages python packages using pip'

    echo "🐍 PIP"
    echo

    set --local pip pip

    # Ensure PIP is installed.
    if not type -q $pip
        error "PIP is not installed."
        return 1
    end

    # # Verify the user owns the site-packages dir.
    # set -l site_packages /usr/local/lib/python2.7/site-packages
    # if test "$USER" != (fileowner $site_packages)
    #     if status is-login
    #         echo "You must be the owner of "$site_packages" to run this command."
    #     end
    #     return 2
    # end

    # Could not install packages due to an EnvironmentError: [Errno 13] Permission denied: '/usr/local/lizard_ext'
    # Consider using the `--user` option or check the permissions.
    if begin user_is_admin; and not test -d /usr/local/lizard_ext; end
        sudo mkdir /usr/local/lizard_ext
        sudo chown $USER /usr/local/lizard_ext
    end

    # Could not install packages due to an EnvironmentError: [Errno 13] Permission denied: '/usr/local/man'
    # Consider using the `--user` option or check the permissions.
    if not test -d /usr/local/man
        sudo mkdir /usr/local/man
        sudo chown $USER /usr/local/man
    end

    set -l global_packages \
        awscli \
        bumpversion \
        lizard \
        powerline-status \
        Pygments \
        pylint \
        powerline-gitstatus \
        powerline-xcodeversion \
        Pygments \
        twine

    set -l uninstall_packages \
        doc2dash

    # Update pip
    $pip install --upgrade pip setuptools wheel

    # Uninstall packages
    for package in $uninstall_packages
        if $pip list | grep --quiet $package
            $pip uninstall $package
        end
    end

    # Install packages
    $pip install --ignore-installed --upgrade --upgrade-strategy eager $global_packages

    # List installed packages
    $pip list
end
