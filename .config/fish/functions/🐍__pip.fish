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

    set -l global_packages powerline-status Pygments

    # Update pip
    pip install --upgrade pip

    # TODO: Uninstall packages
    # TODO: Only install missing packages
    # Install packages
    pip install --upgrade $global_packages

    # List installed packages
    pip list
end
