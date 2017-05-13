# Installs and updates npm modules.
# https://docs.npmjs.com/cli
function 🕸__npm
    echo "🕸  NPM"
    echo

    set -l global_packages fast-cli n ralio

    set -l installed_packages (npm list -g --depth=0)
    # Example output:
    # /usr/local/lib
    # ├── fast-cli@0.2.1
    # ├── n@2.1.7
    # ├── npm@4.5.0
    # └── ralio@0.6.1
    # Manual installation check
    # string match "*ralio*" $installed_packages[5]

    echo "Updating NPM"
    npm install npm@latest -g

    # TODO: Add package uninstall

    # Update
    npm update -g

    # TODO: Refactor to only install missing packages
    #npm install --global $global_packages

    npm doctor
end
