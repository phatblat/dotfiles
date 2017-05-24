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
    if not which -s pip
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

    set -l global_packages powerline-status Pygments \
        # powerline-status fork
        'git+https://github.com/phatblat/powerline-gitstatus.git@segment-spacing'

    # Update pip
    pip install --upgrade pip

    # TODO: Uninstall packages
    # TODO: Only install missing packages
    # Install packages
    pip install --user --ignore-installed --upgrade --upgrade-strategy eager $global_packages

    # List installed packages
    pip list
end
