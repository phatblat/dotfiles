# Manages python packages using pip (https://pip.pypa.io/en/stable/).
# Python Package Index (PyPI) https://pypi.python.org/pypi
#
# Installs Powerline for Vim
# https://powerline.readthedocs.io/en/latest/
#
# Sequencing
# - After: brew (installed with python)
function 🐍__pip
    echo "🐍  PIP"
    echo

    # Ensure PIP is installed.
    if not which -s pip3
        error "PIP is not installed."
        return 1
    end

    # # Verify the user owns the site-packages dir.
    # set -l site_packages /usr/local/lib/python2.7/site-packages
    # if test $USER != (fileowner $site_packages)
    #     if status is-login
    #         echo "You must be the owner of "$site_packages" to run this command."
    #     end
    #     return 2
    # end

    set -l global_packages \
        doc2dash \
        powerline-status \
        Pygments \
        # gitstatus segment fork for powerline-status
        'git+https://github.com/phatblat/powerline-gitstatus.git@segment-spacing'

    # Update pip
    pip3 install --upgrade pip setuptools wheel

    # TODO: Uninstall packages
    # TODO: Only install missing packages
    # Install packages
    pip3 install --user --ignore-installed --upgrade --upgrade-strategy eager $global_packages

    # List installed packages
    pip3 list
end
