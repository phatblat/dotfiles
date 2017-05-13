# Installs and updates npm modules.
function 🕸__npm
    echo "🕸  NPM"
    echo

    set -l global_packages fast-cli n ralio

    echo "Updating NPM"
    npm install npm@latest -g

    npm install --global $global_packages

    npm doctor
end
